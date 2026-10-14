"""Convierte una hoja de piezas sobre fondo magenta en una skin del juego.

Uso (desde la raíz del proyecto):
    python3 tools/import_parts_sheet.py <hoja.png> <nombre_skin> [--side right|left]

La hoja debe tener las 4 piezas separadas sobre magenta liso (#FF00FF), en dos filas:
    arriba:  head, body
    abajo:   arm, leg
(el orden del prompt de docs/prompt_copilot.md).

Genera assets/characters/skins/<nombre_skin>/:
    <pieza>.png    pieza recortada con fondo transparente, a ART_SCALE px por px de juego
    skin.json      punto de unión y escala de cada pieza (el juego no deforma las imágenes)

Con --side left, las piezas se guardan como <pieza>_left.png: la versión que se ve
cuando el personaje mira a la izquierda (debe estar dibujada mirando a la izquierda).
"""
import argparse
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
from rig_spec import PARTS, SHEET_ROWS, ART_SCALE  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def remove_magenta(rgb):
    """Devuelve RGBA: alfa según cuánto se parece cada píxel al magenta, sin halo rosado."""
    rgb = rgb.astype(np.float32)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    magenta = np.minimum(r, b) - g                 # ~240 en el fondo, <=0 en el personaje
    alpha = np.clip((200.0 - magenta) / 140.0, 0.0, 1.0)
    # Recuperar el color real en los bordes semitransparentes: P = a*C + (1-a)*K  →  C = (P-(1-a)*K)/a
    key = np.array([248.0, 2.0, 242.0])
    a = alpha[..., None]
    color = np.where(a > 0.02, (rgb - (1 - a) * key) / np.maximum(a, 0.02), 0)
    out = np.dstack([np.clip(color, 0, 255), alpha * 255]).astype(np.uint8)
    return out


def find_pieces(rgba, expected):
    solid = rgba[..., 3] > 128
    solid = ndimage.binary_closing(solid, iterations=2)
    lab, n = ndimage.label(solid)
    sizes = ndimage.sum(solid, lab, range(1, n + 1))
    big = [i + 1 for i, s in enumerate(sizes) if s > solid.size * 0.002]
    if len(big) != expected:
        raise SystemExit(f"Se esperaban {expected} piezas y se encontraron {len(big)}. "
                         "Revisa que estén separadas y que el fondo sea magenta liso.")
    boxes = []
    for i in big:
        ys, xs = np.where(lab == i)
        boxes.append((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1, i))
    # ordenar en filas (por centro vertical) y dentro de cada fila de izquierda a derecha
    boxes.sort(key=lambda b: (b[1] + b[3]) / 2)
    rows, i = [], 0
    for row_names in SHEET_ROWS:
        row = sorted(boxes[i:i + len(row_names)], key=lambda b: b[0])
        rows.append(row)
        i += len(row_names)
    return lab, rows


def width_at(mask, y):
    xs = np.where(mask[int(np.clip(y, 0, mask.shape[0] - 1))])[0]
    return (xs.min(), xs.max() + 1) if len(xs) else (0, mask.shape[1])


def pivot_and_factor(name, mask):
    """Punto de unión (px de la imagen recortada) y factor para llevarla a ART_SCALE px por px de juego."""
    h, w = mask.shape
    (gw, gh), (px, py), _ = PARTS[name]
    if name in ("arm", "leg"):
        # Extremidad recta colgando: la unión es el centro del extremo redondeado de arriba,
        # y el largo desde la unión hasta el final (puño / planta del pie) define la escala.
        x0, x1 = width_at(mask, h * 0.08)
        pivot = ((x0 + x1) / 2, (x1 - x0) / 2)
        factor = (gh - py) * ART_SCALE / (h - pivot[1])
    else:
        # head, body: ajustar por alto. head: unión en el cuello (abajo);
        # body: unión en la cintura, a la altura que indica la especificación.
        factor = gh * ART_SCALE / h
        y = h * py / gh
        x0, x1 = width_at(mask, min(y, h * 0.97))
        pivot = ((x0 + x1) / 2, y)
    return pivot, factor


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sheet")
    ap.add_argument("skin")
    ap.add_argument("--side", choices=["right", "left"], default="right")
    args = ap.parse_args()

    rgba = remove_magenta(np.array(Image.open(args.sheet).convert("RGB")))
    names = [n for row in SHEET_ROWS for n in row]
    lab, rows = find_pieces(rgba, len(names))
    out_dir = os.path.join(ROOT, "assets/characters/skins", args.skin)
    os.makedirs(out_dir, exist_ok=True)
    meta_path = os.path.join(out_dir, "skin.json")
    meta = json.load(open(meta_path)) if os.path.exists(meta_path) else {}
    meta.setdefault("name", args.skin)
    meta.setdefault("parts", {})

    suffix = "_left" if args.side == "left" else ""
    for row_names, row in zip(SHEET_ROWS, rows):
        for name, (x0, y0, x1, y1, idx) in zip(row_names, row):
            pad = 4
            x0, y0 = max(x0 - pad, 0), max(y0 - pad, 0)
            x1, y1 = min(x1 + pad, rgba.shape[1]), min(y1 + pad, rgba.shape[0])
            crop = rgba[y0:y1, x0:x1].copy()
            own = ndimage.binary_dilation(lab[y0:y1, x0:x1] == idx, iterations=pad)
            crop[..., 3] = np.where(own, crop[..., 3], 0)      # quitar restos de otras piezas
            mask = crop[..., 3] > 128
            (pvx, pvy), f = pivot_and_factor(name, mask)
            img = Image.fromarray(crop)
            size = (max(1, round(img.width * f)), max(1, round(img.height * f)))
            img = img.resize(size, Image.LANCZOS)
            img.save(os.path.join(out_dir, f"{name}{suffix}.png"))
            meta["parts"][f"{name}{suffix}"] = {
                "pivot": [round(pvx * f, 1), round(pvy * f, 1)],
                "scale": round(1.0 / ART_SCALE, 4),
            }
            print(f"  {name + suffix:14s} {size[0]:4d}x{size[1]:<4d} unión ({pvx * f:.0f}, {pvy * f:.0f})")
    with open(meta_path, "w") as fh:
        json.dump(meta, fh, indent=2, ensure_ascii=False)
    print(f"skin '{args.skin}' → {os.path.relpath(out_dir, ROOT)}")


if __name__ == "__main__":
    main()
