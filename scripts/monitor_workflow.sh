#!/bin/bash

# Script de surveillance des workflows Oozie
# Usage: ./monitor_workflow.sh <job_id>

set -e

if [ $# -lt 1 ]; then
    echo "Usage: ./monitor_workflow.sh <job_id>"
    exit 1
fi

JOB_ID=$1
INTERVAL=10  # Intervalle de vérification en secondes

echo "Surveillance du workflow Oozie avec ID: ${JOB_ID}"
echo "Appuyez sur Ctrl+C pour quitter"

while true; do
    # Obtenir le statut du job
    STATUS=$(oozie job -info ${JOB_ID} | grep "Status" | awk '{print $3}')
    
    # Afficher la date/heure et le statut
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Statut: ${STATUS}"
    
    # Si le job est terminé (succès ou échec), sortir de la boucle
    if [ "${STATUS}" == "SUCCEEDED" ] || [ "${STATUS}" == "KILLED" ] || [ "${STATUS}" == "FAILED" ]; then
        echo "Le workflow est terminé avec le statut: ${STATUS}"
        
        # Afficher les actions en échec si le statut est FAILED
        if [ "${STATUS}" == "FAILED" ]; then
            echo "Actions en échec:"
            oozie job -info ${JOB_ID} | grep -A 3 "FAILED"
        fi
        
        break
    fi
    
    # Attendre avant la prochaine vérification
    sleep ${INTERVAL}
done

# Afficher les logs pour le débogage si le job a échoué
if [ "${STATUS}" == "FAILED" ]; then
    echo "Pour consulter les logs détaillés, utilisez:"
    echo "oozie job -log ${JOB_ID}"
fi

exit 0