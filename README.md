# Architecture Bundle Oozie pour le Traitement JSONL

Ce projet implémente un pipeline de traitement de fichiers JSONL en utilisant l'architecture Oozie Bundle/Coordinator/Workflow.

## Architecture

Le pipeline se compose de quatre étapes principales, chacune gérée par un coordinateur distinct :

1. **Analyzer Coordinator** : Analyse les fichiers JSONL d'entrée et les divise en chunks de taille gérable.
2. **Processor Coordinator** : Traite chaque chunk individuellement et en parallèle.
3. **Dependency Coordinator** : Surveille l'achèvement du traitement de tous les chunks.
4. **Merger Coordinator** : Fusionne tous les chunks traités en un résultat final au format Parquet.

Cette architecture présente plusieurs avantages :

- **Parallélisation** : Traitement massif en parallèle des chunks de données.
- **Fiabilité** : Chaque étape est surveillée et peut être relancée individuellement en cas d'échec.
- **Évolutivité** : Facilité d'ajout ou de modification des étapes du pipeline.
- **Orchestration** : Gestion automatique des dépendances entre les étapes.

## Structure des fichiers

```
jsonl-ingestion/
├── bundle/
│   ├── bundle.xml              # Définition du bundle Oozie
│   └── bundle.properties       # Propriétés du bundle
├── coordinator/
│   ├── analyzer-coordinator.xml   # Coordinateur d'analyse
│   ├── processor-coordinator.xml  # Coordinateur de traitement
│   ├── dependency-coordinator.xml # Coordinateur de dépendance
│   └── merger-coordinator.xml     # Coordinateur de fusion
├── workflow/
│   ├── analyzer-workflow.xml      # Workflow d'analyse
│   ├── processor-workflow.xml     # Workflow de traitement
│   ├── dependency-workflow.xml    # Workflow de dépendance
│   └── merger-workflow.xml        # Workflow de fusion
├── scripts/
│   ├── input_analyzer.sh          # Script d'analyse des fichiers
│   ├── process_chunk.sh           # Script de traitement des chunks
│   ├── check_all_processed.sh     # Script de vérification
│   ├── extract_chunk_id.sh        # Script d'extraction d'ID
│   └── result_merger.sh           # Script de fusion des résultats
├── deploy_bundle.sh               # Script de déploiement
├── test_bundle.sh                 # Script de test
└── monitor_workflow.sh            # Script de surveillance
```

## Flux d'exécution

1. **Analyzer Coordinator** : Déclenché par l'existence de fichiers d'entrée.

   - Crée des chunks et un fichier `analyzer_done`.

2. **Processor Coordinator** : Déclenché par l'existence de chunks et du fichier `analyzer_done`.

   - Traite chaque chunk et crée un fichier `.processed` pour chaque chunk.

3. **Dependency Coordinator** : Déclenché par l'existence du fichier `analyzer_done`.

   - Vérifie si tous les chunks sont traités.
   - Crée un fichier `_SUCCESS` dans le répertoire processed.
   - Crée un fichier `processor_done` comme signal de fin.

4. **Merger Coordinator** : Déclenché par l'existence du fichier `_SUCCESS`.
   - Fusionne tous les chunks traités.
   - Crée le résultat final.

## Installation

1. Clonez ce dépôt sur votre edge node Hadoop.
2. Exécutez le script de déploiement :
   ```
   ./deploy_bundle.sh
   ```

## Exécution

1. Pour soumettre le bundle complet :

   ```
   oozie job -config bundle/bundle.properties -run
   ```

2. Pour générer des données de test et déclencher le bundle :

   ```
   ./test_bundle.sh [nombre_d'enregistrements]
   ```

3. Pour surveiller l'exécution d'un job :
   ```
   ./monitor_workflow.sh <job_id>
   ```

## Configuration

Les principaux paramètres sont configurables dans le fichier `bundle.properties` :

- `inputPath` : Chemin des fichiers d'entrée JSONL
- `chunkListDir` : Répertoire temporaire pour les chunks
- `outputDir` : Répertoire de sortie pour les résultats
- `chunkSize` : Taille des chunks en octets (défaut : 1GB)
- `startTime`/`endTime` : Période d'exécution des coordinateurs

## Personnalisation

Pour personnaliser le traitement des données, modifiez principalement le script `process_chunk.sh` pour y ajouter vos propres transformations SparkSQL.

## Dépannage

En cas de problème, consultez les logs Oozie :

```
oozie job -info <job_id>
oozie job -log <job_id>
```

Vous pouvez également vérifier les logs Spark via l'interface YARN.
