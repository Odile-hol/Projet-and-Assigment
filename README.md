# SafeCall Backend

Safecall is a mobile application designed to provide intelligent personal safety by automatically detecting and managing critical situations such as physical assaults, strokes, and severe medical emergencies.

API Flask de classification video/audio basee sur recherche vectorielle Weaviate.

## Fonctionnalites

- Vectorisation audio avec Wav2Vec2.
- Vectorisation video avec CLIP.
- Indexation Weaviate dans 2 collections:
  - VideoEmbeddings
  - AudioEmbeddings
- Classification par similarite (k-NN) avec sortie detaillee:
  - action_class
  - predicted_type
  - violence_classification
  - confidence
  - search_results complets

## Prerequis

- Python 3.10+
- Docker + Docker Compose
- ffmpeg installe sur la machine (accessible en ligne de commande)

## Installation

1. Creer/activer un environnement virtuel.
2. Installer les dependances Python:

```bash
pip install -r requirement.txt
```

## Structure importante

- safecallback.py: API Flask (classification)
- weaviate1.py: ingestion dataset vers Weaviate
- docker-compose.yml: services Weaviate
- violent-action-classes.csv
- nonviolent-action-classes.csv
- action-class-occurrences.csv

## Lancer le projet

### 1) Demarrer Weaviate

```bash
docker-compose up -d
```

### 2) Ingerer les donnees dans Weaviate

```bash
python weaviate1.py
```

### 3) Demarrer l'API

```bash
python safecallback.py
```

API disponible sur:

- http://localhost:5000

## Utilisation de l'API

### Health check

```bash
curl.exe "http://localhost:5000/health"
```

### Classifier un fichier video/audio

```bash
curl.exe -X POST "http://localhost:5000/classify-action" -F "file=@C:/chemin/vers/fichier.mp4"
```

### Endpoint alternatif (meme logique)

```bash
curl.exe -X POST "http://localhost:5000/classify" -F "file=@C:/chemin/vers/fichier.mp4"
```

## Exemple de reponse

```json
{
  "success": true,
  "file": "exemple.mp4",
  "action_class": "fight",
  "predicted_type": "violent",
  "violence_classification": "violent",
  "confidence": 0.86,
  "search_results": [
    {
      "source_collection": "VideoEmbeddings",
      "file": "violent/cam1/xxx.mp4",
      "action": "fight",
      "type": "violent",
      "distance": 0.15,
      "similarity": 0.86
    }
  ],
  "total_request_time_seconds": 4.9
}
```

## Notes

- Le premier appel peut etre plus lent (chargement modele).
- Si CUDA est disponible, PyTorch peut utiliser le GPU.
- Les fichiers uploades ne sont pas inseres dans Weaviate pendant la classification.
