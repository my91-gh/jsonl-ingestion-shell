#!/bin/bash

# Script qui remplace ChunkProcessor.java
# Usage: process_chunk.sh <chunkPath> <processedDir> <sparkMaster> <sparkDriverMemory> <sparkExecutorMemory>

set -e

if [ $# -lt 5 ]; then
    echo "Usage: process_chunk.sh <chunkPath> <processedDir> <sparkMaster> <sparkDriverMemory> <sparkExecutorMemory>"
    exit 1
fi

CHUNK_PATH=$1
PROCESSED_DIR=$2
SPARK_MASTER=$3
SPARK_DRIVER_MEMORY=$4
SPARK_EXECUTOR_MEMORY=$5

# Extraire le nom du fichier à partir du chemin
FILENAME=$(basename "${CHUNK_PATH}")
CHUNK_ID=$(echo ${FILENAME} | sed -n 's/chunk_\([0-9]*\)\.json/\1/p')

OUTPUT_PATH="${CHUNK_PATH%.json}.parquet"
PROCESSED_FLAG="${PROCESSED_DIR}/chunk_${CHUNK_ID}.processed"

echo "Traitement du chunk: ${CHUNK_PATH}"

# Vérifier que le chunk existe
if ! hadoop fs -test -e ${CHUNK_PATH}; then
    echo "Erreur: Le chunk ${CHUNK_PATH} n'existe pas"
    exit 1
fi

# Utiliser Spark pour traiter le chunk
spark-submit --master yarn \
  --class org.apache.spark.examples.SparkPi \
  --name "ChunkProcessor_${CHUNK_INDEX}" \
  --conf "spark.driver.memory=4g" \
  --conf "spark.executor.memory=8g" \
  --conf "spark.yarn.queue=default" \
  --conf "spark.dynamicAllocation.enabled=true" \
  /dev/null 2>&1 << EOF
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import java.util.Date

val spark = SparkSession.builder()
  .appName("ChunkProcessor_${CHUNK_INDEX}")
  .getOrCreate()

// Lire le chunk au format JSON
val chunk = spark.read.json("${CHUNK_PATH}")

// Transformation des données (ajout de colonnes)
val transformed = chunk
  .withColumn("processed_date", lit(new Date().toString))
  .withColumn("status", lit("PROCESSED"))

// Sauvegarder en format Parquet
transformed.write
  .mode("overwrite")
  .parquet("${OUTPUT_PATH}")

// Quitter Spark
spark.stop()
EOF

# Créer le flag pour indiquer que le chunk a été traité
echo "Chunk ${CHUNK_INDEX} traité avec succès."
echo "processed=true" | hadoop fs -put - ${PROCESSED_FLAG}

exit 0