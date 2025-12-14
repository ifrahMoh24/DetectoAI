import io
from typing import List

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
    allow_origins=["*"],  # you can lock this down later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model once at startup
try:
    model = YOLO(MODEL_PATH)
except Exception as e:
    print(f"❌ Failed to load model from {MODEL_PATH}: {e}")
    model = None


@app.get("/")
def root():
    return {"status": "ok", "message": "DetectoAI backend running"}


@app.post("/detect")
async def detect_damage(file: UploadFile = File(...)):
    if model is None:
        raise HTTPException(status_code=500, detail="Model not loaded on server")

    # Basic content check
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    # Read bytes and open with PIL
    image_bytes = await file.read()
    try:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image file")

    # Run inference
    try:
        results = model(image, imgsz=224)[0]  # first (and only) result
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

    # (Optional) build a top-k list
    detections: List[dict] = [
        {
            "label": top1_label,
            "confidence": top1_conf,
        }
    ]

    return {
        "detections": detections,
        "meta": {
            "top1_index": top1_idx,
            "top1_label": top1_label,
            "top1_confidence": top1_conf,
        },
    }
