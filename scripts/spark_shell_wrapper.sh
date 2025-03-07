#!/bin/bash

# Script wrapper pour exécuter du code Scala dans Spark
# Usage: spark_shell_wrapper.sh <scala_script_file> [arguments...]

set -e

if [ $# -lt 1 ]; then
    echo "Usage: spark_shell_wrapper.sh <scala_script_file> [arguments...]"
    exit 1
fi

SCALA_SCRIPT=$1
shift

# Vérifier que le fichier script existe
if [ ! -f ${SCALA_SCRIPT} ]; then
    echo "Erreur: Le fichier script ${SCALA_SCRIPT} n'existe pas"
    exit 1
fi

# Construire la liste des arguments
ARGS=""
for arg in "$@"; do
    ARGS="${ARGS} \"${arg}\""
done

# Exécuter le script Scala dans Spark
spark-shell --master yarn \
  --name "Spark_Shell_Script" \
  --conf "spark.driver.memory=4g" \
  --conf "spark.executor.memory=8g" \
  --conf "spark.dynamicAllocation.enabled=true" \
  -i ${SCALA_SCRIPT} \
  --conf "spark.shell.args=${ARGS}"

exit 0