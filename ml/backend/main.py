import io
from typing import Dict, List

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
from ultralytics import YOLO

# Path to your trained model
MODEL_PATH = "../results/detectoai_cls_best.pt"

app = FastAPI(title="DetectoAI Backend", version="1.0.0")

# Allow Flutter app (and browser) to call the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model once at startup
try:
    model = YOLO(MODEL_PATH)
    print(f"✅ Model loaded from {MODEL_PATH}")
except Exception as e:
    print(f"❌ Failed to load model from {MODEL_PATH}: {e}")
    model = None


@app.get("/")
def root():
    return {"status": "ok", "message": "DetectoAI backend running"}


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": model is not None}


@app.post("/detect")
async def detect_damage(file: UploadFile = File(...)):
    if model is None:
        raise HTTPException(status_code=500, detail="Model not loaded on server")

    # Accept any content type — validate by actually opening with PIL below

    # Read bytes and open with PIL
    image_bytes = await file.read()
    print(f"📥 Received file: {file.filename}, content_type={file.content_type}, size={len(image_bytes)} bytes")
    try:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception as e:
        print(f"❌ PIL error: {e}")
        raise HTTPException(status_code=400, detail=f"Invalid image file: {e}")

    # Run inference
    try:
        results = model(image, imgsz=224)[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference error: {e}")

    # For classification models, use results.probs
    if results.probs is None:
        raise HTTPException(status_code=500, detail="No probabilities returned from model")

    probs = results.probs
    names = model.names  # class index -> label mapping

    # Top-1 prediction
    top1_idx = int(probs.top1)
    top1_conf = float(probs.top1conf)
    top1_label = names[top1_idx]

    # All class probabilities
    prob_data = probs.data.tolist()
    probabilities: Dict[str, float] = {
        names[i]: round(float(p), 4) for i, p in enumerate(prob_data)
    }

    return {
        "prediction": top1_label,
        "damage_type": top1_label,
        "confidence": top1_conf,
        "probabilities": probabilities,
        "detections": [{"label": top1_label, "confidence": top1_conf}],
        "meta": {
            "top1_index": top1_idx,
            "top1_label": top1_label,
            "top1_confidence": top1_conf,
        },
    }
