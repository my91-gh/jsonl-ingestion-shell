#!/bin/bash

# Script de test local équivalent à LocalTest.java
# Usage: ./local_test.sh

set -e

# Définir les chemins
INPUT_PATH="data/input/sample_data.jsonl"
OUTPUT_DIR="data/output"
CHUNK_LIST_DIR="data/temp/chunks"
PROCESSED_DIR="${CHUNK_LIST_DIR}/processed"

echo "=== Préparation des répertoires ==="
# Nettoyer et créer les répertoires
rm -rf ${OUTPUT_DIR}
rm -rf data/temp
mkdir -p ${CHUNK_LIST_DIR}
mkdir -p ${PROCESSED_DIR}

# Vérifier que le fichier d'entrée existe
if [ ! -f ${INPUT_PATH} ]; then
    echo "Création d'un fichier de test JSON..."
    mkdir -p data/input
    cat > ${INPUT_PATH} << EOF
{"id": 1, "name": "Product 1", "price": 10.5, "date": "2025-01-01"}
{"id": 2, "name": "Product 2", "price": 20.0, "date": "2025-01-02"}
{"id": 3, "name": "Product 3", "price": 15.75, "date": "2025-01-03"}
{"id": 4, "name": "Product 4", "price": 8.99, "date": "2025-01-04"}
{"id": 5, "name": "Product 5", "price": 30.0, "date": "2025-01-05"}
EOF
fi

echo "=== Étape 1: Analyse du fichier d'entrée ==="
./scripts/input_analyzer.sh ${INPUT_PATH} ${CHUNK_LIST_DIR}

# Lire le nombre de chunks créés
CHUNKS_COUNT=$(cat ${CHUNK_LIST_DIR}/count)
echo "Nombre de chunks créés: ${CHUNKS_COUNT}"

echo "=== Étape 2: Traitement des chunks ==="
for (( i=0; i<${CHUNKS_COUNT}; i++ )); do
    echo "Traitement du chunk ${i}..."
    ./scripts/process_chunk.sh ${CHUNK_LIST_DIR} ${i}
done

echo "=== Étape 3: Vérification des chunks traités ==="
./scripts/check_all_processed.sh ${CHUNK_LIST_DIR}

echo "=== Étape 4: Fusion des résultats ==="
./scripts/result_merger.sh ${CHUNK_LIST_DIR} ${OUTPUT_DIR}

echo "=== Test terminé ==="
echo "Résultats disponibles dans: ${OUTPUT_DIR}/merged_data.parquet"

exit 0