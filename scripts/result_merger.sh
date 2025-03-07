#!/bin/bash

# Script qui remplace ResultMerger.java
# Usage: result_merger.sh <chunkListDir> <processedDir> <outputDir> <sparkMaster> <sparkDriverMemory> <sparkExecutorMemory>

set -e

if [ $# -lt 6 ]; then
    echo "Usage: result_merger.sh <chunkListDir> <processedDir> <outputDir> <sparkMaster> <sparkDriverMemory> <sparkExecutorMemory>"
    exit 1
fi

CHUNK_LIST_DIR=$1
PROCESSED_DIR=$2
OUTPUT_DIR=$3
SPARK_MASTER=$4
SPARK_DRIVER_MEMORY=$5
SPARK_EXECUTOR_MEMORY=$6

# Vérifier que le répertoire processed existe et contient le flag _SUCCESS
if ! hadoop fs -test -e ${PROCESSED_DIR}/_SUCCESS; then
    echo "Erreur: Le traitement des chunks n'est pas terminé (${PROCESSED_DIR}/_SUCCESS n'existe pas)"
    exit 1
fi

# Créer le répertoire de sortie s'il n'existe pas
hadoop fs -mkdir -p ${OUTPUT_DIR}

# Obtenir le nombre total de chunks
TOTAL_CHUNKS=$(hadoop fs -cat ${CHUNK_LIST_DIR}/count)
echo "Fusion de ${TOTAL_CHUNKS} chunks..."

# Utiliser Spark pour fusionner tous les chunks Parquet
spark-submit --master yarn \
  --class org.apache.spark.examples.SparkPi \
  --name "ResultMerger" \
  --conf "spark.driver.memory=4g" \
  --conf "spark.executor.memory=8g" \
  --conf "spark.yarn.queue=default" \
  --conf "spark.dynamicAllocation.enabled=true" \
  /dev/null 2>&1 << EOF
import org.apache.spark.sql.SparkSession

val spark = SparkSession.builder()
  .appName("ResultMerger")
  .getOrCreate()

// Collecter tous les chemins de fichiers Parquet
val parquetPaths = (0 until ${TOTAL_CHUNKS}).map { i =>
  "${CHUNK_LIST_DIR}/chunk_" + i + ".parquet"
}.toArray

// Lire et fusionner tous les fichiers Parquet
val mergedData = spark.read.parquet(parquetPaths: _*)

// Sauvegarder le résultat final
mergedData.write
  .mode("overwrite")
  .parquet("${OUTPUT_DIR}/merged_data.parquet")

// Quitter Spark
spark.stop()
EOF

echo "Fusion terminée. Résultat sauvegardé dans: ${OUTPUT_DIR}/merged_data.parquet"

# Créer un flag _SUCCESS dans le répertoire de sortie
touch _SUCCESS
hadoop fs -put -f _SUCCESS ${OUTPUT_DIR}/_SUCCESS
rm _SUCCESS

exit 0