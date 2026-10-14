"""Recorta animaciones de la hoja de presentación y genera tiras PNG transparentes."""
import sys
from PIL import Image
import numpy as np
from scipy import ndimage

SRC, OUT = sys.argv[1], sys.argv[2]
im = np.array(Image.open(SRC).convert("RGB")).astype(int)

# (x0, y0, x1, y1, número de figuras) en la imagen original
REGIONS = {
    "idle": (10, 66, 260, 137, 7),
    "walk": (268, 66, 487, 137, 6),
    "jump": (495, 66, 752, 137, 6),
}
LUM_MAX, BLUE_MIN = int(sys.argv[3]) if len(sys.argv) > 3 else 34, 5


def foreground(sub):
    lum = sub.mean(axis=2)
    blue = sub[..., 2] - sub[..., 0]
    bg = (lum < LUM_MAX) & (blue >= BLUE_MIN)
    bg |= lum < 14  # negro casi puro del fondo
    fg = ~bg
    fg = ndimage.binary_opening(fg, iterations=1)
    lab, n = ndimage.label(fg)
    if n == 0:
        return fg
    sizes = ndimage.sum(fg, lab, range(1, n + 1))
    body = lab == (int(np.argmax(sizes)) + 1)
    # sumar piezas cercanas al cuerpo (zapatillas, puños) e ignorar manchas lejanas
    near = ndimage.binary_dilation(body, iterations=2)
    keep = body.copy()
    for i, s in enumerate(sizes, 1):
        comp = lab == i
        if s >= 6 and (comp & near).any():
            keep |= comp
    keep = ndimage.binary_closing(keep, iterations=2)
    return ndimage.binary_fill_holes(keep)


all_frames = {}
for name, (x0, y0, x1, y1, n) in REGIONS.items():
    region = im[y0:y1, x0:x1]
    pitch = (x1 - x0) / n
    frames = []
    for i in range(n):
        cx0, cx1 = int(round(i * pitch)), int(round((i + 1) * pitch))
        sub = region[:, cx0:cx1]
        fg = foreground(sub)
        ys, xs = np.where(fg)
        fy0, fy1, fx0, fx1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        rgba = np.zeros((fy1 - fy0, fx1 - fx0, 4), np.uint8)
        rgba[..., :3] = sub[fy0:fy1, fx0:fx1]
        rgba[..., 3] = fg[fy0:fy1, fx0:fx1] * 255
        # ancla: centro de los pies (fila inferior) para alinear sin "temblor"
        foot_xs = np.where(fg[fy1 - 4:fy1, fx0:fx1].any(axis=0))[0]
        anchor = int(foot_xs.mean()) if len(foot_xs) else (fx1 - fx0) // 2
        frames.append((rgba, anchor))
    all_frames[name] = frames

# Celda común para todas las animaciones: pies centrados abajo.
every = [fa for fr in all_frames.values() for fa in fr]
half = max(max(a, f.shape[1] - a) for f, a in every) + 2
fw = half * 2
fh = max(f.shape[0] for f, _ in every) + 1
for name, frames in all_frames.items():
    strip = np.zeros((fh, fw * len(frames), 4), np.uint8)
    for i, (f, a) in enumerate(frames):
        h, w = f.shape[:2]
        ox, oy = i * fw + half - a, fh - h
        strip[oy:oy + h, ox:ox + w] = f
    Image.fromarray(strip).save(f"{OUT}/{name}.png")
    print(f"{name} {len(frames)} {fw} {fh}")
