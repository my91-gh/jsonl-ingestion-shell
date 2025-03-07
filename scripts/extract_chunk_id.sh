#!/bin/bash

# Script pour extraire l'ID du chunk à partir du chemin
# Usage: extract_chunk_id.sh <chunkPath>

set -e

if [ $# -lt 1 ]; then
    echo "Usage: extract_chunk_id.sh <chunkPath>"
    exit 1
fi

CHUNK_PATH=$1

# Extraire le nom du fichier à partir du chemin complet
FILENAME=$(basename "${CHUNK_PATH}")

# Extraire l'ID du chunk (le numéro entre "chunk_" et ".json")
CHUNK_ID=$(echo ${FILENAME} | sed -n 's/chunk_\([0-9]*\)\.json/\1/p')

if [ -z "${CHUNK_ID}" ]; then
    echo "Erreur: Impossible d'extraire l'ID du chunk à partir de ${CHUNK_PATH}"
    exit 1
fi

echo "Chunk ID extrait: ${CHUNK_ID}"
echo "chunk_id=${CHUNK_ID}"

exit 0