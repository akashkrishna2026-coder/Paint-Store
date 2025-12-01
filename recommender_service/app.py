from __future__ import annotations
import os
from typing import List, Dict, Any
from fastapi import FastAPI, HTTPException, Query
import firebase_admin
from firebase_admin import credentials, db
from compute import build_counts, build_cooccurrence, knn_neighbors

app = FastAPI(title="Paint Store Recommender")

# --- Firebase setup ---
# Requires: set env GOOGLE_APPLICATION_CREDENTIALS to service account json path
# And set FIREBASE_DB_URL to your RTDB URL

_initialized = False

def _init_firebase() -> None:
    global _initialized
    if _initialized:
        return
    cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    db_url = os.environ.get("FIREBASE_DB_URL")
    if not cred_path or not db_url:
        raise RuntimeError("Missing GOOGLE_APPLICATION_CREDENTIALS or FIREBASE_DB_URL env var")
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred, {"databaseURL": db_url})
    _initialized = True


def _fetch_orders() -> List[Dict[str, Any]]:
    ref = db.reference("orders")
    snap = ref.get() or {}
    if not isinstance(snap, dict):
        return []
    return [v for v in snap.values() if isinstance(v, dict)]


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/popular", response_model=List[str])
async def popular(limit: int = Query(10, ge=1, le=100)):
    try:
        _init_firebase()
        orders = _fetch_orders()
        counts = build_counts(orders)
        keys = sorted(counts.items(), key=lambda x: x[1], reverse=True)
        return [k for k, _ in keys[:limit]]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/similar/{product_id}", response_model=List[str])
async def similar(product_id: str, k: int = Query(10, ge=1, le=100)):
    try:
        _init_firebase()
        orders = _fetch_orders()
        co = build_cooccurrence(orders)
        return knn_neighbors(product_id, co, k=k)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
