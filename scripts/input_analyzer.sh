#!/bin/bash

# Script qui remplace InputAnalyzer.java
# Usage: input_analyzer.sh <inputPath> <chunkListDir> <chunkSizeBytes>

set -e

if [ $# -lt 3 ]; then
    echo "Usage: input_analyzer.sh <inputPath> <chunkListDir> <chunkSizeBytes>"
    exit 1
fi

INPUT_PATH=$1
CHUNK_LIST_DIR=$2
CHUNK_SIZE_BYTES=$3  # Taille du chunk en octets, passée en paramètre

# S'assurer que le répertoire de destination existe
hadoop fs -mkdir -p ${CHUNK_LIST_DIR}
hadoop fs -mkdir -p ${CHUNK_LIST_DIR}/processed

# Analyser le fichier d'entrée JSON
echo "Analyse du fichier d'entrée: ${INPUT_PATH}"

# Compter le nombre total de lignes (peut prendre du temps sur de gros fichiers)
TOTAL_LINES=$(hadoop fs -cat ${INPUT_PATH} | wc -l)
echo "Nombre total de lignes: ${TOTAL_LINES}"

# Estimer la taille moyenne par ligne
TOTAL_SIZE=$(hadoop fs -du -s ${INPUT_PATH} | awk '{print $1}')
AVG_LINE_SIZE=$((TOTAL_SIZE / TOTAL_LINES))
echo "Taille moyenne par ligne: ${AVG_LINE_SIZE} bytes"

# Calculer le nombre de lignes par chunk
LINES_PER_CHUNK=$((CHUNK_SIZE_BYTES / AVG_LINE_SIZE))
LINES_PER_CHUNK=$((LINES_PER_CHUNK > 0 ? LINES_PER_CHUNK : 1))
echo "Lignes estimées par chunk: ${LINES_PER_CHUNK}"

# Calculer le nombre total de chunks
CHUNKS_COUNT=$(((TOTAL_LINES + LINES_PER_CHUNK - 1) / LINES_PER_CHUNK))
echo "Nombre total de chunks: ${CHUNKS_COUNT}"

# Utiliser Spark pour diviser le fichier en chunks
spark-submit --master yarn \
  --class org.apache.spark.examples.SparkPi \
  --name "InputAnalyzer" \
  --conf "spark.driver.memory=4g" \
  --conf "spark.executor.memory=8g" \
  --conf "spark.yarn.queue=default" \
  --conf "spark.dynamicAllocation.enabled=true" \
  /dev/null 2>&1 << EOF
import org.apache.spark.sql.SparkSession

val spark = SparkSession.builder()
  .appName("InputAnalyzer")
  .getOrCreate()

// Lire le fichier JSON
val input = spark.read.json("${INPUT_PATH}")

// Diviser en chunks de taille approximativement égale
val totalRows = ${TOTAL_LINES}
val rowsPerChunk = ${LINES_PER_CHUNK}

// Créer une vue temporaire
input.createOrReplaceTempView("input_data")

// Créer les chunks
for (i <- 0 until ${CHUNKS_COUNT}) {
  val offset = i * rowsPerChunk
  val limit = if (i == ${CHUNKS_COUNT} - 1) totalRows - offset else rowsPerChunk
  val chunkPath = "${CHUNK_LIST_DIR}/chunk_" + i + ".json"
  
  spark.sql(s"SELECT * FROM input_data LIMIT $limit OFFSET $offset")
    .write
    .json(chunkPath)
    
  // Écrire les infos du chunk
  val chunkInfo = s"""{"path":"$chunkPath","startOffset":$offset,"size":$limit,"status":"PENDING"}"""
  spark.sparkContext.parallelize(Seq(chunkInfo)).coalesce(1)
    .saveAsTextFile("${CHUNK_LIST_DIR}/chunk_info_" + i)
}

// Quitter Spark
spark.stop()
EOF

# Sauvegarder le nombre total de chunks
echo ${CHUNKS_COUNT} | hadoop fs -put - ${CHUNK_LIST_DIR}/count

# Créer le flag pour indiquer que l'analyse est terminée
touch analyzer_done
hadoop fs -put analyzer_done ${CHUNK_LIST_DIR}/analyzer_done
rm analyzer_done

# Retourner la valeur pour le workflow Oozie
echo "Analyse terminée. ${CHUNKS_COUNT} chunks créés."
echo "chunks_count=${CHUNKS_COUNT}"

exit 0