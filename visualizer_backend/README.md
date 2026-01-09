# Visualizer Backend (FastAPI + ONNXRuntime + OpenCV + Firebase Storage)

CPU-only backend for automatic paint color visualization. It segments walls/building facades and recolors them in LAB space to preserve lighting and texture.

- FastAPI (REST)
- ONNXRuntime (semantic segmentation on ADE20K or similar)
- OpenCV (LAB recoloring with luminance preservation)
- Firebase Storage (host result image and return URL)

## Safety and secrets
- Do NOT commit your Firebase service account JSON.
- Provide paths/keys via environment variables only.
- Prefer a private VPS or trusted PaaS.

## Requirements
- Python 3.10+
- CPU (1–2 vCPU is fine)
- A segmentation ONNX model with known class IDs for `wall` and `building` (ADE20K-style)

Install:
```
python -m venv .venv
source .venv/bin/activate
pip install -r visualizer_backend/requirements.txt
```

## Environment variables
- `MODEL_PATH` Absolute path to your ONNX model (required)
- `ORT_THREADS` Number of CPU threads for ONNXRuntime (default: 1)
- `FIREBASE_STORAGE_BUCKET` Firebase Storage bucket (e.g., my-project.appspot.com) (required)
- `GOOGLE_APPLICATION_CREDENTIALS` Path to service account JSON (required)
- `PUBLIC_READ` `true|false` (default: true) make uploaded images public
- `MAX_IMAGE_SIDE` Resize longest side before processing (default: 1600)
- `MIN_MASK_RATIO` Reject images with tiny masks (default: 0.08)
- `WALL_CLASS` Class index for wall in your model (default: 12)
- `BUILDING_CLASS` Class index for building in your model (default: 2)

## Run locally
```
uvicorn visualizer_backend.main:app --host 0.0.0.0 --port 8000
```
Health check:
```
curl http://127.0.0.1:8000/health
```

## API
POST /visualize (multipart/form-data)
- `image` (file)
- `color_hex` (string, e.g. #C9D6FF)
- `scene` (string, optional: auto|interior|exterior; default auto)

Response 200:
```
{ "image_url": "https://.../visualizer/<id>.jpg" }
```

Errors:
- 400: invalid image / no suitable wall/building detected / bad color
- 500: internal error / upload failed
- 503: segmentation session not ready (model not configured)

### Example (curl)
```
curl -X POST \
  -F "image=@/path/room.jpg" \
  -F "color_hex=#95C8D8" \
  -F "scene=auto" \
  http://127.0.0.1:8000/visualize
```

## Deployment notes (proceed with caution)
- Use a small VPS (1–2 vCPU); set `ORT_THREADS=1` initially.
- Restrict CORS to your app domain if possible (edit CORSMiddleware in main.py).
- Set rate-limiting at proxy (e.g., nginx) to control costs.
- Monitor logs and set alerts for error spikes.
- Keep your service account JSON OFF the repo and restrict its permissions.

## Tuning and quality
- Adjust `alpha` in `recolor_with_lab` (default 0.7) for stronger/weaker color.
- Tune `WALL_CLASS` and `BUILDING_CLASS` to your model mapping.
- Increase `MAX_IMAGE_SIDE` for more detail (costs more CPU).
- Raise `MIN_MASK_RATIO` to reject low-quality photos early.

## Roadmap
- Cache masks by image hash to reuse for multiple colors.
- Optional: separate endpoints for interior/exterior.
- Add signed URL flow if public access is not desired.
