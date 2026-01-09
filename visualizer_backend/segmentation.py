import os
from functools import lru_cache
from typing import Literal

import numpy as np

Scene = Literal["auto", "interior", "exterior"]

try:
    import onnxruntime as ort  # type: ignore
except Exception:  # pragma: no cover
    ort = None  # onnxruntime optional at import time


@lru_cache(maxsize=1)
def _load_session():
    model_path = os.getenv("MODEL_PATH")
    if not model_path or not os.path.exists(model_path):
        raise RuntimeError(
            "Segmentation model not configured. Set MODEL_PATH to an ONNX file path on the server.")
    if ort is None:
        raise RuntimeError(
            "onnxruntime is not available. Ensure it is installed on the server.")
    so = ort.SessionOptions()
    so.intra_op_num_threads = int(os.getenv("ORT_THREADS", "1"))
    session = ort.InferenceSession(model_path, providers=["CPUExecutionProvider"], sess_options=so)
    return session


def _preprocess(img: np.ndarray, size: int = 512) -> tuple[np.ndarray, float, tuple[int, int]]:
    h, w = img.shape[:2]
    scale = size / max(h, w)
    nh, nw = int(h * scale), int(w * scale)
    resized = cv_add_resize(img, (nw, nh))
    # pad to square
    pad_top = (size - nh) // 2
    pad_bottom = size - nh - pad_top
    pad_left = (size - nw) // 2
    pad_right = size - nw - pad_left
    padded = np.pad(resized, ((pad_top, pad_bottom), (pad_left, pad_right), (0, 0)), mode="constant")
    inp = padded.astype(np.float32) / 255.0
    inp = inp.transpose(2, 0, 1)[None, ...]  # NCHW
    return inp, scale, (pad_top, pad_left)


def cv_add_resize(img: np.ndarray, size: tuple[int, int]) -> np.ndarray:
    import cv2
    return cv2.resize(img, size, interpolation=cv2.INTER_AREA)


def _postprocess(logits: np.ndarray, orig_shape: tuple[int, int], scale: float, pad: tuple[int, int],
                 scene: Scene) -> np.ndarray:
    import cv2
    # logits shape: (N, C, H, W) -> we take argmax over C
    pred = logits.argmax(axis=1)[0].astype(np.uint8)  # (H, W)
    # remove padding, resize back
    H, W = pred.shape
    pt, pl = pad
    valid = pred[pt:H - pt, pl:W - pl] if (pt + pl) > 0 else pred
    oh, ow = orig_shape
    mask = cv2.resize(valid, (ow, oh), interpolation=cv2.INTER_NEAREST)

    # Map class indices to target mask
    # NOTE: You must align these with your model's class mapping (e.g., ADE20K indices)
    # For example purposes, assume: wall=12, building=2 (placeholder)
    WALL_CLASS = int(os.getenv("WALL_CLASS", "12"))
    BUILDING_CLASS = int(os.getenv("BUILDING_CLASS", "2"))

    if scene == "interior":
        target = (mask == WALL_CLASS)
    elif scene == "exterior":
        target = (mask == BUILDING_CLASS)
    else:
        # auto: pick larger area between wall and building
        wall_area = np.count_nonzero(mask == WALL_CLASS)
        bld_area = np.count_nonzero(mask == BUILDING_CLASS)
        target = (mask == (WALL_CLASS if wall_area >= bld_area else BUILDING_CLASS))

    target_u8 = target.astype(np.uint8) * 255
    # Feather edges lightly
    target_u8 = cv2.GaussianBlur(target_u8, (5, 5), 0)
    return target_u8


def get_mask(img_bgr: np.ndarray, scene: Scene = "auto") -> np.ndarray:
    """
    Returns a uint8 mask (0-255) where 255 indicates pixels to recolor.
    Raises RuntimeError if the model/session is not configured.
    """
    session = _load_session()
    inp, scale, pad = _preprocess(img_bgr)
    inputs = {session.get_inputs()[0].name: inp}
    outputs = session.run(None, inputs)
    logits = outputs[0]  # assume first output is logits
    mask = _postprocess(logits, (img_bgr.shape[0], img_bgr.shape[1]), scale, pad, scene)
    return mask
