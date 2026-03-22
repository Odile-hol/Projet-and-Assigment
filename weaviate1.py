import os
import cv2
import numpy as np
import subprocess
import librosa
import torch
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

from transformers import (
    Wav2Vec2Processor,
    Wav2Vec2Model,
    CLIPProcessor,
    CLIPModel,
)

import pandas as pd
import weaviate
from weaviate.classes.config import Configure, DataType, Property


# ========================
# HELPERS
# ========================
def clean_columns(df: pd.DataFrame) -> pd.DataFrame:
    df.columns = [c.strip() for c in df.columns]
    return df

def safe_label(value) -> str | None:
    if pd.isna(value):
        return None
    label = str(value).strip()
    return label if label else None


# ========================
# CONFIG
# ========================
VIDEO_EXTENSIONS = [".mp4", ".avi", ".mov", ".mkv"]
AUDIO_EXTENSIONS = [".wav", ".mp3", ".flac"]

device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Device: {device}")


# ========================
# MODELS
# ========================
processor = Wav2Vec2Processor.from_pretrained("facebook/wav2vec2-base-960h")
wav2vec = Wav2Vec2Model.from_pretrained("facebook/wav2vec2-base-960h").to(device)

clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32").to(device)

wav2vec.eval()
clip_model.eval()


# ========================
# FILE TYPE
# ========================
def get_file_type(path):
    ext = os.path.splitext(path)[1].lower()
    if ext in VIDEO_EXTENSIONS:
        return "video"
    if ext in AUDIO_EXTENSIONS:
        return "audio"
    return "unknown"


# ========================
# AUDIO EXTRACTION
# ========================
def extract_audio(video_path, output_audio="temp_audio.wav"):
    # Check si audio existe proprement avec ffprobe
    probe_cmd = [
        "ffprobe", "-v", "error",
        "-select_streams", "a",
        "-show_entries", "stream=codec_type",
        "-of", "default=nw=1",
        video_path
    ]

    probe = subprocess.run(probe_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if "codec_type=audio" not in probe.stdout.decode():
        return None

    cmd = [
        "ffmpeg", "-y",
        "-i", video_path,
        "-ar", "16000",
        "-ac", "1",
        "-vn",  # 👈 IMPORTANT : pas de vidéo
        output_audio,
    ]

    try:
        subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    except subprocess.CalledProcessError as e:
        print(f"FFMPEG error: {e.stderr.decode()}")
        return None

    return output_audio if os.path.exists(output_audio) else None


# ========================
# FRAME EXTRACTION
# ========================
def extract_frames(video_path, fps=1, max_frames=32):
    cap = cv2.VideoCapture(video_path)
    frames = []

    original_fps = cap.get(cv2.CAP_PROP_FPS)
    interval = int(original_fps / fps) if original_fps and original_fps > 0 else 1

    count = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        if count % interval == 0:
            frame = cv2.resize(frame, (224, 224))
            frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            frames.append(frame)

        if len(frames) >= max_frames:
            break

        count += 1

    cap.release()
    return frames


# ========================
# AUDIO EMBEDDING
# ========================
def audio_to_embedding(audio_path):
    try:
        audio, _ = librosa.load(audio_path, sr=16000)

        inputs = processor(audio, return_tensors="pt", sampling_rate=16000)
        inputs = {k: v.to(device) for k, v in inputs.items()}

        with torch.no_grad():
            outputs = wav2vec(**inputs)

        emb = outputs.last_hidden_state.mean(dim=1).squeeze().cpu().numpy()

        norm = np.linalg.norm(emb)
        if norm > 0:
            emb = emb / norm

        return emb

    except Exception as e:
        print(f"Audio embedding error: {e}")
        return None


# ========================
# VIDEO EMBEDDING
# ========================
def video_to_embedding(frames):
    if len(frames) == 0:
        return None

    try:
        inputs = clip_processor(images=frames, return_tensors="pt", padding=True)
        inputs = {k: v.to(device) for k, v in inputs.items()}

        with torch.no_grad():
            # Depending on transformers version/model internals, this may return
            # either a Tensor or a model output object.
            features = clip_model.get_image_features(**inputs)

            if isinstance(features, torch.Tensor):
                emb_tensor = features
            else:
                emb_tensor = getattr(features, "image_embeds", None)
                if emb_tensor is None:
                    emb_tensor = getattr(features, "pooler_output", None)
                if emb_tensor is None:
                    forward_out = clip_model(**inputs)
                    emb_tensor = getattr(forward_out, "image_embeds", None)
                    if emb_tensor is None:
                        emb_tensor = getattr(forward_out, "pooler_output", None)
                if emb_tensor is None:
                    raise ValueError("Unable to extract image embeddings from CLIP output")

        if emb_tensor.dim() == 1:
            emb = emb_tensor.detach().cpu().numpy()
        else:
            emb = emb_tensor.mean(dim=0).detach().cpu().numpy()

        norm = np.linalg.norm(emb)
        if norm > 0:
            emb = emb / norm

        return emb

    except Exception as e:
        print(f"Video embedding error: {e}")
        return None


# ========================
# PROCESS FILE
# ========================
def process_file(path):
    file_type = get_file_type(path)

    result = {
        "file_type": file_type,
        "audio_embedding": None,
        "video_embedding": None
    }

    if file_type == "video":
        audio_path = extract_audio(path)

        if audio_path:
            result["audio_embedding"] = audio_to_embedding(audio_path)
            if os.path.exists(audio_path):
                os.remove(audio_path)

        frames = extract_frames(path)
        result["video_embedding"] = video_to_embedding(frames)

    elif file_type == "audio":
        result["audio_embedding"] = audio_to_embedding(path)

    return result


# ========================
# WEAVIATE
# ========================
def ensure_collections(client):
    collection_map = {
        "video": "VideoEmbeddings",
        "audio": "AudioEmbeddings",
    }

    existing = client.collections.list_all()

    for name in collection_map.values():
        if name not in existing:
            client.collections.create(
                name=name,
                properties=[
                    Property(name="file", data_type=DataType.TEXT),
                    Property(name="action", data_type=DataType.TEXT),
                    Property(name="type", data_type=DataType.TEXT),
                    Property(name="secondary_actions", data_type=DataType.TEXT_ARRAY),
                    Property(name="tertiary_actions", data_type=DataType.TEXT_ARRAY),
                    Property(name="all_actions", data_type=DataType.TEXT_ARRAY),
                    Property(name="source_csv", data_type=DataType.TEXT),
                    Property(name="violent_flag", data_type=DataType.TEXT),
                    Property(name="embedding_kind", data_type=DataType.TEXT),
                ],
                vector_config=Configure.Vectors.self_provided(name="default"),
            )

    return collection_map


def load_action_data() -> pd.DataFrame:
    violent = clean_columns(pd.read_csv("violent-action-classes.csv"))
    non_violent = clean_columns(pd.read_csv("nonviolent-action-classes.csv"))

    if "troisiemeclasse" not in violent.columns:
        violent["troisiemeclasse"] = None
    if "troisiemeclasse" not in non_violent.columns:
        non_violent["troisiemeclasse"] = None

    violent["type"] = "violent"
    non_violent["type"] = "non_violent"
    violent["source_csv"] = "violent-action-classes.csv"
    non_violent["source_csv"] = "nonviolent-action-classes.csv"

    return pd.concat([violent, non_violent], ignore_index=True)


def load_violent_flag_by_action() -> dict[str, str]:
    if not os.path.exists("action-class-occurrences.csv"):
        return {}

    df = clean_columns(pd.read_csv("action-class-occurrences.csv"))
    if "ACTION CLASS" not in df.columns or "VIOLENT" not in df.columns:
        return {}

    mapping: dict[str, str] = {}
    for _, row in df.iterrows():
        action = safe_label(row.get("ACTION CLASS"))
        flag = safe_label(row.get("VIOLENT"))
        if not action or not flag:
            continue
        mapping[action.lower()] = "violent" if flag.lower() == "y" else "non_violent"

    return mapping


def build_media_index(base_dir: Path):
    type_to_folder = {
        "violent": "violent",
        "non_violent": "non-violent",
    }

    media_index = {"violent": {}, "non_violent": {}}
    valid_extensions = set(VIDEO_EXTENSIONS + AUDIO_EXTENSIONS)

    for action_type, folder_name in type_to_folder.items():
        root = base_dir / folder_name
        if not root.exists():
            continue

        for path in root.rglob("*"):
            if path.is_file() and path.suffix.lower() in valid_extensions:
                media_index[action_type].setdefault(path.name, []).append(path)

    return media_index


# ========================
# INGESTION
# ========================
def process_and_insert(file_path, base_properties, audio_collection, video_collection):
    try:
        embeddings = process_file(str(file_path))
    except Exception as e:
        print(f"Error: {file_path} -> {e}")
        return 0, 1

    inserted = 0

    if embeddings["audio_embedding"] is not None:
        audio_collection.data.insert(
            properties={**base_properties, "embedding_kind": "audio"},
            vector=embeddings["audio_embedding"].tolist(),
        )
        inserted += 1

    if embeddings["video_embedding"] is not None:
        video_collection.data.insert(
            properties={**base_properties, "embedding_kind": "video"},
            vector=embeddings["video_embedding"].tolist(),
        )
        inserted += 1

    return inserted, 0


def ingest_vectors(client, df, base_dir: Path):
    media_index = build_media_index(base_dir)
    violent_flag_by_action = load_violent_flag_by_action()

    video_collection = client.collections.get("VideoEmbeddings")
    audio_collection = client.collections.get("AudioEmbeddings")

    tasks = []

    with ThreadPoolExecutor(max_workers=4) as executor:
        for _, row in df.iterrows():
            file_name = safe_label(row.get("FILE"))
            action = safe_label(row.get("ACTIONCLASSES"))
            second_action = safe_label(row.get("secondeclasse"))
            third_action = safe_label(row.get("troisiemeclasse"))
            action_type = safe_label(row.get("type")) or "unknown"
            source_csv = safe_label(row.get("source_csv")) or "unknown"

            if not file_name or not action:
                continue

            all_actions = [label for label in [action, second_action, third_action] if label]
            violent_flag = violent_flag_by_action.get(action.lower(), action_type)

            paths = media_index.get(action_type, {}).get(file_name, [])
            for path in paths:
                base_props = {
                    "file": str(path),
                    "action": action,
                    "type": action_type,
                    "secondary_actions": [second_action] if second_action else [],
                    "tertiary_actions": [third_action] if third_action else [],
                    "all_actions": all_actions,
                    "source_csv": source_csv,
                    "violent_flag": violent_flag,
                }

                tasks.append(
                    executor.submit(
                        process_and_insert,
                        path,
                        base_props,
                        audio_collection,
                        video_collection,
                    )
                )

        inserted = 0
        skipped = 0
        for future in as_completed(tasks):
            i, s = future.result()
            inserted += i
            skipped += s

    print(f"Inserted: {inserted} | Skipped: {skipped}")


# ========================
# MAIN
# ========================
def main():
    df = load_action_data()
    client = weaviate.connect_to_local()

    try:
        ensure_collections(client)
        ingest_vectors(client, df, Path("."))
    finally:
        client.close()


if __name__ == "__main__":
    main()