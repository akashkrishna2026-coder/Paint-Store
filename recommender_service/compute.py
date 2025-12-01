from __future__ import annotations
from collections import defaultdict
from math import sqrt
from typing import Dict, List, Iterable

# Core co-occurrence + cosine similarity utilities

def build_counts(orders: Iterable[dict]) -> Dict[str, int]:
    counts: Dict[str, int] = defaultdict(int)
    for o in orders:
        items = o.get("items") or []
        for it in items:
            k = str(it)
            if k:
                counts[k] += 1
    return dict(counts)


def build_cooccurrence(orders: Iterable[dict]) -> Dict[str, Dict[str, int]]:
    co: Dict[str, Dict[str, int]] = defaultdict(lambda: defaultdict(int))
    for o in orders:
        items = [str(x) for x in (o.get("items") or []) if str(x)]
        n = len(items)
        for i in range(n):
            for j in range(i + 1, n):
                a, b = items[i], items[j]
                if a == b:
                    continue
                co[a][b] += 1
                co[b][a] += 1
    # convert inner dicts to normal dicts
    return {k: dict(v) for k, v in co.items()}


def cosine(a: Dict[str, int], b: Dict[str, int]) -> float:
    if not a or not b:
        return 0.0
    keys = set(a) | set(b)
    dot = 0.0
    na = 0.0
    nb = 0.0
    for v in a.values():
        na += v * v
    for v in b.values():
        nb += v * v
    for k in keys:
        dot += float(a.get(k, 0)) * float(b.get(k, 0))
    denom = sqrt(max(na, 1.0)) * sqrt(max(nb, 1.0))
    return 0.0 if denom == 0 else dot / denom


def knn_neighbors(product_key: str, co: Dict[str, Dict[str, int]], k: int = 10) -> List[str]:
    target = co.get(product_key) or {}
    scores = []
    for other, vec in co.items():
        if other == product_key:
            continue
        s = cosine(target, vec)
        if s > 0:
            scores.append((other, s))
    scores.sort(key=lambda x: x[1], reverse=True)
    return [p for p, _ in scores[:k]]
