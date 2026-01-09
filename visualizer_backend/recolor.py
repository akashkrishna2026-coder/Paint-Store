from __future__ import annotations

import colorsys
from typing import Tuple

import cv2
import numpy as np


def _hex_to_rgb(hex_str: str) -> Tuple[int, int, int]:
    s = hex_str.strip().lstrip('#')
    if len(s) != 6:
        raise ValueError('Invalid color hex; expected #RRGGBB')
    r = int(s[0:2], 16)
    g = int(s[2:4], 16)
    b = int(s[4:6], 16)
    return r, g, b


def recolor_with_lab(src_bgr: np.ndarray, mask_u8: np.ndarray, color_hex: str, alpha: float = 0.7) -> np.ndarray:
    """
    Recolor using LAB: keep luminance (L) from source, steer A/B toward target color.
    alpha controls the strength [0..1].
    """
    if src_bgr is None or src_bgr.ndim != 3 or src_bgr.shape[2] != 3:
        raise ValueError('Invalid input image')
    if mask_u8 is None or mask_u8.ndim != 2:
        raise ValueError('Invalid mask')

    r, g, b = _hex_to_rgb(color_hex)
    target_bgr = np.array([[[b, g, r]]], dtype=np.uint8)
    target_lab = cv2.cvtColor(target_bgr, cv2.COLOR_BGR2LAB)[0, 0].astype(np.float32)

    lab = cv2.cvtColor(src_bgr, cv2.COLOR_BGR2LAB).astype(np.float32)
    L, A, B = cv2.split(lab)

    # Normalize mask [0..1]
    m = (mask_u8.astype(np.float32) / 255.0)
    m = cv2.merge([m, m, m])  # broadcast to 3 channels

    # Build target planes matching source shape
    tgtA = np.full_like(A, target_lab[1])
    tgtB = np.full_like(B, target_lab[2])

    # Adaptive alpha: reduce strength in very dark regions to avoid plastic look
    # scale alpha by normalized L (0..1)
    L_norm = L / 255.0
    adapt_alpha = (alpha * (0.6 + 0.4 * L_norm)).astype(np.float32)

    # Blend only inside mask
    A_out = A * (1 - m[:, :, 0] * adapt_alpha) + tgtA * (m[:, :, 0] * adapt_alpha)
    B_out = B * (1 - m[:, :, 0] * adapt_alpha) + tgtB * (m[:, :, 0] * adapt_alpha)

    lab_out = cv2.merge([L, A_out, B_out])
    lab_out = np.clip(lab_out, 0, 255).astype(np.uint8)
    out_bgr = cv2.cvtColor(lab_out, cv2.COLOR_LAB2BGR)
    return out_bgr
