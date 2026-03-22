import os
import cv2
import numpy as np
import subprocess
import librosa
import torch
from transformers import Wav2Vec2Processor, Wav2Vec2Model, CLIPProcessor, CLIPModel
import weaviate
from pathlib import Path
from werkzeug.utils import secure_filename
import pandas as pd
from flask import Flask, request, jsonify
import tempfile
import time
import threading
from weaviate.classes.config import Configure, DataType, Property
from weaviate.classes.query import MetadataQuery

# ================= CONFIG =================
app = Flask(__name__)
UPLOAD_FOLDER = tempfile.gettempdir()

VIDEO_EXTENSIONS = [".mp4", ".avi", ".mov", ".mkv"]
AUDIO_EXTENSIONS = [".wav", ".mp3", ".flac"]

device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Device: {device}")

# If top-3 neighbors are very close, use majority type vote (2/3).
TOP3_DISTANCE_SPREAD_THRESHOLD = 0.08

# ================= MODELS =================
processor = None
wav2vec = None
clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32").to(device)
clip_model.eval()

MODEL_LOCK = threading.Lock()

def ensure_audio_model_loaded():
    global processor, wav2vec
    with MODEL_LOCK:
        if processor is None:
            processor = Wav2Vec2Processor.from_pretrained("facebook/wav2vec2-base-960h")
        if wav2vec is None:
            wav2vec = Wav2Vec2Model.from_pretrained("facebook/wav2vec2-base-960h").to(device)
            wav2vec.eval()

# ================= UTILS =================
def get_file_type(path):
    ext = os.path.splitext(path)[1].lower()
    if ext in VIDEO_EXTENSIONS:
        return "video"
    if ext in AUDIO_EXTENSIONS:
        return "audio"
    return "unknown"

# ================= FFMPEG FIX =================
def extract_audio(video_path, output_audio="temp_audio.wav"):
    cmd = [
        "ffmpeg", "-y", "-i", video_path,
        "-ar", "16000", "-ac", "1", output_audio
    ]
    try:
        subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    except subprocess.CalledProcessError as e:
        print("FFMPEG ERROR:", e.stderr.decode())
        return None
    return output_audio if os.path.exists(output_audio) else None

# ================= FRAME EXTRACTION =================
def extract_frames(video_path, max_frames=32):
    cap = cv2.VideoCapture(video_path)
    frames = []

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame = cv2.resize(frame, (224, 224))
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        frames.append(frame)

        if len(frames) >= max_frames:
            break

    cap.release()
    return frames

# ================= AUDIO EMBEDDING =================
def audio_to_embedding(audio_path):
    try:
        ensure_audio_model_loaded()
        audio, _ = librosa.load(audio_path, sr=16000)

        inputs = processor(audio, return_tensors="pt", sampling_rate=16000)
        inputs = {k: v.to(device) for k, v in inputs.items()}

        with torch.no_grad():
            outputs = wav2vec(**inputs)

        emb = outputs.last_hidden_state.mean(dim=1).squeeze().cpu().numpy()
        norm = np.linalg.norm(emb)
        return emb / norm if norm > 0 else emb

    except Exception as e:
        print("Audio error:", e)
        return None

# ================= VIDEO EMBEDDING (CLIP) =================
def video_to_embedding(frames):
    if not frames:
        return None
    try:
        inputs = clip_processor(images=frames, return_tensors="pt", padding=True)
        inputs = {k: v.to(device) for k, v in inputs.items()}

        with torch.no_grad():
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
                    raise ValueError("Unable to extract CLIP image embeddings")

        emb = emb_tensor.mean(dim=0).detach().cpu().numpy() if emb_tensor.dim() > 1 else emb_tensor.detach().cpu().numpy()
        norm = np.linalg.norm(emb)
        return emb / norm if norm > 0 else emb

    except Exception as e:
        print("Video error:", e)
        return None

# ================= PROCESS MEDIA =================
def process_media_file(path):
    file_type = get_file_type(path)

    result = {
        "audio_embedding": None,
        "video_embedding": None,
        "fusion_embedding": None,
        "file_type": file_type
    }

    if file_type == "video":
        audio_path = extract_audio(path)

        if audio_path:
            result["audio_embedding"] = audio_to_embedding(audio_path)
            os.remove(audio_path)

        frames = extract_frames(path)
        result["video_embedding"] = video_to_embedding(frames)

        if result["audio_embedding"] is not None and result["video_embedding"] is not None:
            fusion = np.concatenate([result["video_embedding"], result["audio_embedding"]])
            fusion_norm = np.linalg.norm(fusion)
            result["fusion_embedding"] = fusion / fusion_norm if fusion_norm > 0 else fusion

    elif file_type == "audio":
        result["audio_embedding"] = audio_to_embedding(path)

    return result

# ================= SIMILARITY =================
def distance_to_similarity(distance):
    if distance is None:
        return None
    return float(np.exp(-distance))

# ================= WEAVIATE =================
def search_similarity(collection_name, embedding):
    client = weaviate.connect_to_local()
    try:
        coll = client.collections.get(collection_name)
        vector = embedding.tolist()

        return coll.query.near_vector(
            near_vector=vector,
            limit=3,
            return_metadata=MetadataQuery(distance=True)
        )
    finally:
        client.close()

def _format_result_item(obj, source_collection):
    props = obj.properties or {}
    distance = obj.metadata.distance if hasattr(obj, "metadata") and hasattr(obj.metadata, "distance") else None
    return {
        "source_collection": source_collection,
        "file": props.get("file"),
        "action": props.get("action"),
        "type": props.get("type"),
        "secondary_actions": props.get("secondary_actions", []),
        "tertiary_actions": props.get("tertiary_actions", []),
        "all_actions": props.get("all_actions", []),
        "violent_flag": props.get("violent_flag"),
        "embedding_kind": props.get("embedding_kind"),
        "distance": distance,
        "similarity": distance_to_similarity(distance),
    }


# ================= CLASSIFICATION =================
def classify(file_path, filename):
    started = time.time()
    emb = process_media_file(file_path)

    search_results = []
    searched_collections = []

    if emb["video_embedding"] is not None:
        try:
            video_results = search_similarity("VideoEmbeddings", emb["video_embedding"])
            searched_collections.append("VideoEmbeddings")
            for obj in video_results.objects:
                search_results.append(_format_result_item(obj, "VideoEmbeddings"))
        except Exception as exc:
            search_results.append({"source_collection": "VideoEmbeddings", "error": str(exc)})

    if emb["audio_embedding"] is not None:
        try:
            audio_results = search_similarity("AudioEmbeddings", emb["audio_embedding"])
            searched_collections.append("AudioEmbeddings")
            for obj in audio_results.objects:
                search_results.append(_format_result_item(obj, "AudioEmbeddings"))
        except Exception as exc:
            search_results.append({"source_collection": "AudioEmbeddings", "error": str(exc)})

    valid = [r for r in search_results if isinstance(r, dict) and "distance" in r and r.get("distance") is not None]
    valid.sort(key=lambda x: x["distance"])

    top = valid[0] if valid else None
    final = top
    decision_rule = "top1"
    top3_close = False

    if len(valid) >= 3:
        top3 = valid[:3]
        dmin = top3[0]["distance"]
        dmax = top3[-1]["distance"]
        spread = dmax - dmin
        top3_close = spread <= TOP3_DISTANCE_SPREAD_THRESHOLD

        if top3_close:
            type_counts = {}
            for item in top3:
                t = item.get("type")
                if not t:
                    continue
                type_counts[t] = type_counts.get(t, 0) + 1

            majority_type = None
            for t, count in type_counts.items():
                if count >= 2:
                    majority_type = t
                    break

            if majority_type:
                for item in top3:
                    if item.get("type") == majority_type:
                        final = item
                        decision_rule = "top3_majority_type"
                        break

    violence = final.get("violent_flag") if final else None
    confidence = final.get("similarity") if final else None

    return {
        "success": True,
        "file": filename,
        "searched_collections": searched_collections,
        "action_class": final.get("action") if final else None,
        "predicted_type": final.get("type") if final else None,
        "violence_classification": violence,
        "confidence": confidence,
        "decision_rule": decision_rule,
        "top3_close_distance": top3_close,
        "top3_distance_spread_threshold": TOP3_DISTANCE_SPREAD_THRESHOLD,
        "search_results": valid,
        "total_request_time_seconds": time.time() - started,
    }

# ================= ROUTE =================
@app.route("/classify", methods=["POST"])
def classify_route():
    if "file" not in request.files:
        return jsonify({"error": "No file"}), 400

    file = request.files["file"]
    filename = secure_filename(file.filename)

    temp_path = os.path.join(UPLOAD_FOLDER, filename)
    file.save(temp_path)

    try:
        result = classify(temp_path, filename)
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

    return jsonify(result)


@app.route("/classify-action", methods=["POST"])
def classify_action_route():
    return classify_route()

# ================= MAIN =================
if __name__ == "__main__":
    print("API ready")
    app.run(host="0.0.0.0", port=5000)