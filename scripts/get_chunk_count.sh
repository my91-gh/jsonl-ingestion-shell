#!/bin/bash

# Script pour obtenir le nombre de chunks à traiter
# Usage: get_chunk_count.sh <chunkListDir>

set -e

if [ $# -lt 1 ]; then
    echo "Usage: get_chunk_count.sh <chunkListDir>"
    exit 1
fi

CHUNK_LIST_DIR=$1

# Vérifier que le fichier count existe
if ! hadoop fs -test -e ${CHUNK_LIST_DIR}/count; then
    echo "Erreur: Le fichier ${CHUNK_LIST_DIR}/count n'existe pas"
    exit 1
fi

# Lire le nombre total de chunks
TOTAL_CHUNKS=$(hadoop fs -cat ${CHUNK_LIST_DIR}/count)
echo "Nombre total de chunks: ${TOTAL_CHUNKS}"

# Retourner la valeur pour le workflow Oozie
echo "total_chunks=${TOTAL_CHUNKS}"

exit 0