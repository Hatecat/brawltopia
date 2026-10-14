"""Dibuja las piezas provisorias (skin "default") y la plantilla de referencia.

Uso (desde la raíz del proyecto): python3 tools/make_placeholder_skin.py
Genera:
  assets/characters/skins/default/<pieza>.png   piezas provisorias con fondo transparente
  docs/skin_template.png                        plantilla: cajas, puntos de unión y nombres
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
from rig_spec import PARTS, SHEET_ROWS, ART_SCALE, art_size, art_pivot  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIN_DIR = os.path.join(ROOT, "assets/characters/skins/default")
S = ART_SCALE

SKIN = (222, 168, 132)
SKIN_DARK = (170, 118, 90)
SHIRT = (52, 54, 62)
PANTS = (30, 30, 36)
STRIPE = (225, 225, 230)
SHOE = (238, 238, 242)
BEARD = (48, 34, 28)
OUTLINE = (12, 12, 16)
RING = (40, 120, 230)
OW = 3  # grosor del contorno en px de arte


def canvas(name):
    return Image.new("RGBA", art_size(name), (0, 0, 0, 0))


def capsule(d, x0, y0, x1, y1, fill):
    r = min(x1 - x0, y1 - y0) // 2
    d.rounded_rectangle((x0, y0, x1, y1), radius=r, fill=fill, outline=OUTLINE, width=OW)


def head():
    im = Image.new("RGBA", (88, 96), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    w, h = im.size
    d.rounded_rectangle((26, 74, 62, 96), radius=8, fill=SKIN, outline=OUTLINE, width=OW)    # cuello
    d.ellipse((6, 2, 84, 86), fill=SKIN, outline=OUTLINE, width=OW)                          # cráneo
    d.chord((30, 34, 86, 90), 0, 180, fill=BEARD, outline=OUTLINE, width=OW)                 # barba
    d.polygon([(80, 40), (88, 52), (80, 54)], fill=SKIN, outline=OUTLINE)                    # nariz
    d.rectangle((62, 34, 70, 40), fill=OUTLINE)                                              # ojo
    d.rectangle((54, 26, 74, 29), fill=BEARD)                                                # ceja
    d.ellipse((24, 42, 38, 60), fill=SKIN_DARK, outline=OUTLINE, width=2)                    # oreja
    d.ellipse((24, 56, 34, 66), outline=RING, width=3)                                       # aro azul
    return im.resize(art_size("head"), Image.LANCZOS)


def torso():
    im = canvas("torso"); d = ImageDraw.Draw(im)
    w, h = im.size
    d.rounded_rectangle((8, 4, w - 8, h - 2), radius=26, fill=SHIRT, outline=OUTLINE, width=OW)
    d.line((w // 2 + 10, 20, w // 2 + 14, h - 20), fill=(70, 72, 82), width=3)              # arruga
    return im


def pelvis():
    im = canvas("pelvis"); d = ImageDraw.Draw(im)
    w, h = im.size
    d.rounded_rectangle((4, 0, w - 4, h - 2), radius=14, fill=PANTS, outline=OUTLINE, width=OW)
    d.rectangle((8, 6, w - 8, 14), fill=(60, 50, 40))                                        # cinturón
    return im


def upper_arm():
    im = canvas("upper_arm"); d = ImageDraw.Draw(im)
    w, h = im.size
    capsule(d, 1, 1, w - 2, h - 2, SKIN)
    d.rounded_rectangle((1, 1, w - 2, 30), radius=14, fill=SHIRT, outline=OUTLINE, width=OW)  # manga
    return im


def forearm():
    im = canvas("forearm"); d = ImageDraw.Draw(im)
    w, h = im.size
    capsule(d, 3, 1, w - 4, h - 22, SKIN)
    d.rounded_rectangle((0, h - 30, w - 1, h - 1), radius=10, fill=SKIN, outline=OUTLINE, width=OW)  # puño
    d.line((6, h - 18, w - 8, h - 18), fill=SKIN_DARK, width=2)
    return im


def thigh():
    im = canvas("thigh"); d = ImageDraw.Draw(im)
    w, h = im.size
    capsule(d, 1, 1, w - 2, h - 2, PANTS)
    d.line((8, 16, 8, h - 16), fill=STRIPE, width=4)                                          # franja
    return im


def shin():
    im = canvas("shin"); d = ImageDraw.Draw(im)
    w, h = im.size
    capsule(d, 2, 1, 38, h - 18, PANTS)
    d.line((9, 16, 9, h - 24), fill=STRIPE, width=4)
    d.rounded_rectangle((2, h - 26, w - 1, h - 1), radius=9, fill=SHOE, outline=OUTLINE, width=OW)  # zapatilla
    d.line((6, h - 8, w - 4, h - 8), fill=(170, 170, 178), width=3)                           # suela
    return im


DRAW = {"head": head, "torso": torso, "pelvis": pelvis, "upper_arm": upper_arm,
        "forearm": forearm, "thigh": thigh, "shin": shin}


def template(parts):
    """Plantilla: cada pieza en su caja, con su punto de unión y nombre, sobre magenta."""
    pad, label_h = 40, 36
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 18)
    small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
    rows = [[art_size(n) for n in row] for row in SHEET_ROWS]
    col_w = max(max(w for w, _ in r) for r in rows) + 60
    width = pad + max(len(r) for r in rows) * (col_w + pad) + 80
    height = pad + sum(max(h for _, h in r) + label_h * 2 + pad for r in rows)
    im = Image.new("RGB", (width, height), (255, 0, 255))
    d = ImageDraw.Draw(im)
    y = pad
    for row in SHEET_ROWS:
        row_h = max(art_size(n)[1] for n in row)
        for i, n in enumerate(row):
            w, h = art_size(n)
            x = pad + i * (col_w + pad) + (col_w - w) // 2
            d.text((x, y), n, fill=(0, 0, 0), font=font)
            by = y + label_h
            d.rectangle((x - 1, by - 1, x + w, by + h), outline=(0, 0, 0), width=1)
            im.paste(parts[n], (x, by), parts[n])
            px, py = art_pivot(n)
            d.ellipse((x + px - 5, by + py - 5, x + px + 5, by + py + 5), outline=(0, 200, 255), width=3)
            d.text((x, by + h + 4), f"{w}x{h}  unión ({px},{py})", fill=(0, 0, 0), font=small)
        y += row_h + label_h * 2 + pad
    return im


if __name__ == "__main__":
    os.makedirs(SKIN_DIR, exist_ok=True)
    parts = {n: f() for n, f in DRAW.items()}
    for n, im in parts.items():
        assert im.size == art_size(n), n
        im.save(os.path.join(SKIN_DIR, f"{n}.png"))
    os.makedirs(os.path.join(ROOT, "docs"), exist_ok=True)
    template(parts).save(os.path.join(ROOT, "docs/skin_template.png"))
    print("piezas:", ", ".join(f"{n} {parts[n].size}" for n in parts))
