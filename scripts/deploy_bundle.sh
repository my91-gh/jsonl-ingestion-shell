#!/bin/bash

# Script de déploiement pour le bundle Oozie
# Usage: ./deploy_bundle.sh

set -e

# Définir les variables
HDFS_USER_DIR="hdfs:///user/${USER}"
LOCAL_DIR="$(pwd)"
APP_NAME="jsonl-ingestion"

# Structure des répertoires
echo "Création de la structure de répertoires locale..."
mkdir -p ${LOCAL_DIR}/scripts
mkdir -p ${LOCAL_DIR}/bundle
mkdir -p ${LOCAL_DIR}/coordinator
mkdir -p ${LOCAL_DIR}/workflow

# Copier les fichiers dans les répertoires locaux
cp bundle.xml ${LOCAL_DIR}/bundle/
cp bundle.properties ${LOCAL_DIR}/bundle/

# Copier les coordinateurs
cp analyzer-coordinator.xml ${LOCAL_DIR}/coordinator/
cp processor-coordinator.xml ${LOCAL_DIR}/coordinator/
cp dependency-coordinator.xml ${LOCAL_DIR}/coordinator/
cp merger-coordinator.xml ${LOCAL_DIR}/coordinator/

# Copier les workflows
cp analyzer-workflow.xml ${LOCAL_DIR}/workflow/
cp processor-workflow.xml ${LOCAL_DIR}/workflow/
cp dependency-workflow.xml ${LOCAL_DIR}/workflow/
cp merger-workflow.xml ${LOCAL_DIR}/workflow/

# Copier les scripts shell
cp input_analyzer.sh ${LOCAL_DIR}/scripts/
cp process_chunk.sh ${LOCAL_DIR}/scripts/
cp check_all_processed.sh ${LOCAL_DIR}/scripts/
cp extract_chunk_id.sh ${LOCAL_DIR}/scripts/
cp result_merger.sh ${LOCAL_DIR}/scripts/

# Rendre les scripts exécutables
chmod +x ${LOCAL_DIR}/scripts/*.sh

# Créer les répertoires sur HDFS
echo "Création des répertoires sur HDFS..."
hdfs dfs -mkdir -p ${HDFS_USER_DIR}/${APP_NAME}/bundle
hdfs dfs -mkdir -p ${HDFS_USER_DIR}/${APP_NAME}/coordinator
hdfs dfs -mkdir -p ${HDFS_USER_DIR}/${APP_NAME}/workflow
hdfs dfs -mkdir -p ${HDFS_USER_DIR}/${APP_NAME}/scripts

# Copier les fichiers sur HDFS
echo "Copie des fichiers sur HDFS..."
hdfs dfs -put -f ${LOCAL_DIR}/bundle/bundle.xml ${HDFS_USER_DIR}/${APP_NAME}/bundle/
hdfs dfs -put -f ${LOCAL_DIR}/coordinator/*.xml ${HDFS_USER_DIR}/${APP_NAME}/coordinator/
hdfs dfs -put -f ${LOCAL_DIR}/workflow/*.xml ${HDFS_USER_DIR}/${APP_NAME}/workflow/
hdfs dfs -put -f ${LOCAL_DIR}/scripts/*.sh ${HDFS_USER_DIR}/${APP_NAME}/scripts/

# Créer les répertoires de données si nécessaires
hdfs dfs -mkdir -p ${HDFS_USER_DIR}/data/input
hdfs dfs -mkdir -p ${HDFS_USER_DIR}/data/output
hdfs dfs -mkdir -p ${HDFS_USER_DIR}/data/temp/chunks

echo "Déploiement terminé avec succès!"
echo "Pour soumettre le bundle, utilisez:"
echo "oozie job -config ${LOCAL_DIR}/bundle/bundle.properties -run"

exit 0