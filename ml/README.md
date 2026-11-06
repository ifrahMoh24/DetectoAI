# DetectoAI – ML & Backend

YOLO-based smartphone damage classifier (crack / dent / scratch / pristine) with a FastAPI inference server.

## Structure

```
ml/
├── dataset/          # Training images grouped by class
│   ├── crack/
│   ├── dent/
│   ├── pristine/
│   └── scratch/
├── backend/
│   ├── main.py       # FastAPI server
│   └── requirements.txt
├── results/
│   ├── detectoai_cls_best.pt    # Trained YOLOv8 model
│   └── detectoai_cls_best.onnx
└── export_to_tflite.py
```

## Running the Backend

```bash
cd ml/backend
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The server exposes:
- `GET /health` – liveness check (returns `{"status":"ok","model_loaded":true}`)
- `POST /detect` – upload an image, get back prediction + all class probabilities

### Example response

```json
{
  "prediction": "scratch",
  "damage_type": "scratch",
  "confidence": 0.973,
  "probabilities": {
    "crack": 0.0012,
    "dent": 0.0085,
    "pristine": 0.0173,
    "scratch": 0.973
  }
}
```

## Flutter App Config

Edit `app/.env` to point at the backend:

```
API_BASE_URL=http://<your-machine-ip>:8000
```

Use `127.0.0.1` for the same machine, or your LAN IP for a physical device.
