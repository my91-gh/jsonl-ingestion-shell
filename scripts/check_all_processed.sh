#!/bin/bash

# Script qui remplace ChunkDependencyManager.java
# Usage: check_all_processed.sh <chunkListDir> <processedDir>

set -e

if [ $# -lt 2 ]; then
    echo "Usage: check_all_processed.sh <chunkListDir> <processedDir>"
    exit 1
fi

CHUNK_LIST_DIR=$1
PROCESSED_DIR=$2

# Vérifier que le répertoire processed existe
if ! hadoop fs -test -e ${PROCESSED_DIR}; then
    echo "Erreur: Le répertoire ${PROCESSED_DIR} n'existe pas"
    echo "all_processed=false"
    exit 1
fi

# Lire le nombre total de chunks
TOTAL_CHUNKS=$(hadoop fs -cat ${CHUNK_LIST_DIR}/count)
echo "Nombre total de chunks: ${TOTAL_CHUNKS}"

# Compter le nombre de chunks traités
PROCESSED_COUNT=$(hadoop fs -ls ${PROCESSED_DIR}/*.processed 2>/dev/null | wc -l)
echo "Nombre de chunks traités: ${PROCESSED_COUNT}"

# Vérifier si tous les chunks ont été traités
if [ ${PROCESSED_COUNT} -ge ${TOTAL_CHUNKS} ]; then
    echo "Tous les chunks ont été traités."
    
    # Créer le flag _SUCCESS
    echo "Création du flag de succès"
    touch _SUCCESS
    hadoop fs -put -f _SUCCESS ${PROCESSED_DIR}/_SUCCESS
    rm _SUCCESS
    
    echo "all_processed=true"
else
    echo "Tous les chunks n'ont pas encore été traités."
    echo "all_processed=false"
    exit 1
fi

exit 0