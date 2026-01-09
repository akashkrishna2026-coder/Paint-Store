import io
import os
import uuid
from typing import Optional

import cv2
import numpy as np
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from segmentation import get_mask
from recolor import recolor_with_lab
from storage import upload_to_firebase

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MAX_SIDE = int(os.getenv("MAX_IMAGE_SIDE", "1600"))
MIN_MASK_RATIO = float(os.getenv("MIN_MASK_RATIO", "0.08"))


def _read_image_bytes(file_bytes: bytes) -> np.ndarray:
    arr = np.frombuffer(file_bytes, dtype=np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        raise HTTPException(status_code=400, detail="Invalid image file")
    return img


def _resize_keep_aspect(img: np.ndarray, max_side: int) -> np.ndarray:
    h, w = img.shape[:2]
    side = max(h, w)
    if side <= max_side:
        return img
    scale = max_side / side
    new_w, new_h = int(w * scale), int(h * scale)
    return cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_AREA)


@app.post("/visualize")
async def visualize(
    image: UploadFile = File(...),
    color_hex: str = Form(...),
    scene: str = Form("auto"),  # "auto" | "interior" | "exterior"
) -> JSONResponse:
    try:
        raw = await image.read()
        src = _read_image_bytes(raw)
        src = _resize_keep_aspect(src, MAX_SIDE)

        try:
            mask = get_mask(src, scene=scene)
        except RuntimeError as e:
            raise HTTPException(status_code=503, detail=str(e))

        if mask.dtype != np.uint8:
            mask = mask.astype(np.uint8)
        if mask.max() <= 1:
            mask = (mask * 255).astype(np.uint8)

        h, w = mask.shape[:2]
        if (mask > 127).sum() < MIN_MASK_RATIO * h * w:
            raise HTTPException(status_code=400, detail="No suitable wall/building found in this photo")

        try:
            result = recolor_with_lab(src, mask, color_hex=color_hex, alpha=0.7)
        except ValueError as ve:
            raise HTTPException(status_code=400, detail=str(ve))

        ok, buf = cv2.imencode(".jpg", result, [int(cv2.IMWRITE_JPEG_QUALITY), 88])
        if not ok:
            raise HTTPException(status_code=500, detail="Failed to encode result image")

        key = f"visualizer/{uuid.uuid4().hex}.jpg"
        try:
            url = upload_to_firebase(io.BytesIO(buf.tobytes()), key, content_type="image/jpeg")
        except Exception as up_e:
            raise HTTPException(status_code=500, detail=f"Upload failed: {up_e}")

        return JSONResponse({"image_url": url})
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Unexpected error while processing image")


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
