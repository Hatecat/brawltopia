"""Recorta animaciones de la hoja de presentación y genera tiras PNG transparentes."""
import sys
from PIL import Image
import numpy as np
from scipy import ndimage

SRC, OUT = sys.argv[1], sys.argv[2]
im = np.array(Image.open(SRC).convert("RGB")).astype(int)

# (x0, y0, x1, y1, número de figuras o 0 = separar por espacios, anclaje)
# anclaje "feet": centro de ambos pies; "backfoot": pie de apoyo (trasero) fijo.
REGIONS = {
    "idle": (10, 66, 260, 137, 7, "feet"),
    "walk": (268, 66, 487, 137, 6, "feet"),
    "jump": (495, 66, 752, 137, 6, "feet"),
    "punch": (6, 157, 400, 230,
              [(6, 44), (44, 85), (85, 133), (132, 177), (176, 213), (212, 262), (260, 299), (300, 352), (350, 397)],
              "backfoot"),
    # cortes manuales (x absolutos): las figuras de la patada se solapan
    "kick": (405, 157, 797, 230,
             [(405, 446), (446, 483), (482, 536), (536, 591, [(574, 160, 593, 181)]), (575, 613, [(574, 181, 588, 195)]), (616, 688), (688, 740), (742, 797)],
             "backfoot"),
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


def raw_fg(sub):
    lum = sub.mean(axis=2)
    blue = sub[..., 2] - sub[..., 0]
    bg = ((lum < LUM_MAX) & (blue >= BLUE_MIN)) | (lum < 14)
    return ndimage.binary_opening(~bg, iterations=1)


def cells(region, n):
    w = region.shape[1]
    if n:
        pitch = w / n
        return [(int(round(i * pitch)), int(round((i + 1) * pitch))) for i in range(n)]
    # separar por columnas vacías
    cols = raw_fg(region).sum(axis=0)
    runs, start = [], None
    for x, c in enumerate(list(cols) + [0]):
        if c > 1 and start is None:
            start = x
        elif c <= 1 and start is not None:
            if x - start >= 10:
                runs.append([start, x])
            start = None
    return [(max(a - 1, 0), min(b + 1, w)) for a, b in runs]


all_frames = {}
for name, (x0, y0, x1, y1, n, mode) in REGIONS.items():
    region = im[y0:y1, x0:x1]
    frames = []
    if isinstance(n, list):
        cuts = [(c[0] - x0, c[1] - x0, c[2] if len(c) > 2 else []) for c in n]
    else:
        cuts = [(a, b, []) for a, b in cells(region, n)]
    for cx0, cx1, erase in cuts:
        sub = region[:, cx0:cx1].copy()
        for ex0, ey0, ex1, ey1 in erase:  # pintar de fondo trozos de figuras vecinas
            sub[max(ey0 - y0, 0):ey1 - y0, max(ex0 - x0 - cx0, 0):ex1 - x0 - cx0] = (12, 14, 26)
        fg = foreground(sub)
        ys, xs = np.where(fg)
        fy0, fy1, fx0, fx1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        rgba = np.zeros((fy1 - fy0, fx1 - fx0, 4), np.uint8)
        rgba[..., :3] = sub[fy0:fy1, fx0:fx1]
        rgba[..., 3] = fg[fy0:fy1, fx0:fx1] * 255
        # zapatillas: píxeles claros en las filas inferiores (más fiables que la silueta)
        bottom = rgba[-7:]
        shoe = (bottom[..., :3].mean(axis=2) > 130) & (bottom[..., 3] > 0)
        foot_xs = np.where(shoe.any(axis=0))[0]
        if len(foot_xs) == 0:
            foot_xs = np.where(bottom[..., 3].any(axis=0))[0]
        center, back = int((foot_xs.min() + foot_xs.max()) / 2), int(foot_xs.min())
        frames.append([rgba, center, back])
    if mode == "backfoot":
        # el pie trasero queda fijo; la distancia pie trasero→centro se toma del cuadro 0
        offset = frames[0][1] - frames[0][2]
        frames = [(f, back + offset) for f, _, back in frames]
    else:
        frames = [(f, center) for f, center, _ in frames]
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
