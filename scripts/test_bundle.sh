#!/bin/bash

# Script pour générer des données de test et déclencher le bundle Oozie
# Usage: ./test_bundle.sh [num_records] [job_id]

set -e

# Paramètres par défaut
NUM_RECORDS=${1:-1000}
JOB_ID=$2

HDFS_USER_DIR="hdfs:///user/${USER}"
TEST_DATA_FILE="test_data_$(date +%Y%m%d%H%M%S).jsonl"
LOCAL_TEST_DATA="/tmp/${TEST_DATA_FILE}"

echo "Génération de ${NUM_RECORDS} enregistrements de test..."

# Génération des données de test au format JSONL
for ((i=1; i<=NUM_RECORDS; i++)); do
  TIMESTAMP=$(date -d "2024-01-01 + ${i} hours" +"%Y-%m-%d %H:%M:%S")
  PRODUCT_ID=$((1000 + RANDOM % 1000))
  PRICE=$(echo "scale=2; 10 + (RANDOM % 1000) / 100" | bc)
  QUANTITY=$((1 + RANDOM % 100))
  TOTAL=$(echo "${PRICE} * ${QUANTITY}" | bc)
  
  echo "{\"id\":${i},\"timestamp\":\"${TIMESTAMP}\",\"product_id\":${PRODUCT_ID},\"price\":${PRICE},\"quantity\":${QUANTITY},\"total\":${TOTAL}}" >> ${LOCAL_TEST_DATA}
done

echo "Chargement des données de test sur HDFS..."
hdfs dfs -put -f ${LOCAL_TEST_DATA} ${HDFS_USER_DIR}/data/input/

echo "Données de test chargées: ${HDFS_USER_DIR}/data/input/${TEST_DATA_FILE}"

# Si un JOB_ID est fourni, on surveille ce job
if [ ! -z "${JOB_ID}" ]; then
  echo "Surveillance du job Oozie ${JOB_ID}..."
  ./monitor_workflow.sh ${JOB_ID}
else
  echo "Pour soumettre le bundle, exécutez:"
  echo "oozie job -config bundle/bundle.properties -run"
fi

# Nettoyage
rm ${LOCAL_TEST_DATA}

exit 0