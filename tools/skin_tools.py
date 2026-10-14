"""Utilidades para skins: unir piezas en una sola imagen y convertir skins antiguas.

Uso como script (convierte una skin de 7 piezas al formato actual de 4 piezas):
    python3 tools/skin_tools.py convert <carpeta_7_piezas> <nombre_skin_nueva>

Formato antiguo (7 piezas): head, torso, pelvis, upper_arm, forearm, thigh, shin.
Formato actual (4 piezas):  head, body (= torso + pelvis), arm (= upper_arm + forearm),
                            leg (= thigh + shin).
"""
import json
import os
import shutil
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from rig_spec import ART_SCALE, BEND  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Puntos de unión del formato antiguo (px de arte), para skins antiguas sin skin.json.
LEGACY_PIVOTS = {
    "head": (36, 72), "torso": (48, 104), "pelvis": (44, 8),
    "upper_arm": (16, 16), "forearm": (16, 16), "thigh": (20, 20), "shin": (20, 20),
}


def compose(layers):
    """Une capas en una imagen. Cada capa: (imagen RGBA, su punto de unión, dónde va ese punto).

    Las posiciones son relativas al punto de unión de la pieza resultante (0, 0).
    Se dibujan en orden: la última queda encima. Devuelve (imagen, punto de unión).
    """
    boxes = []
    for img, (px, py), (ox, oy) in layers:
        x0, y0 = ox - px, oy - py
        boxes.append((x0, y0, x0 + img.width, y0 + img.height))
    min_x = min(b[0] for b in boxes)
    min_y = min(b[1] for b in boxes)
    w = round(max(b[2] for b in boxes) - min_x)
    h = round(max(b[3] for b in boxes) - min_y)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for (img, _, _), (x0, y0, _, _) in zip(layers, boxes):
        out.alpha_composite(img, (round(x0 - min_x), round(y0 - min_y)))
    return out, (-min_x, -min_y)


def compose_legacy(pieces, pivots):
    """De 7 piezas a 4. pieces: {nombre: Image}, pivots: {nombre: (x, y)} en px de arte."""
    s = ART_SCALE
    arm, arm_pv = compose([
        (pieces["upper_arm"], pivots["upper_arm"], (0, 0)),
        (pieces["forearm"], pivots["forearm"], (0, BEND["arm"][0] * s)),   # antebrazo desde el codo
    ])
    leg, leg_pv = compose([
        (pieces["thigh"], pivots["thigh"], (0, 0)),
        (pieces["shin"], pivots["shin"], (0, BEND["leg"][0] * s)),          # pierna desde la rodilla
    ])
    body, body_pv = compose([
        (pieces["pelvis"], pivots["pelvis"], (0, 0)),                      # cadera debajo
        (pieces["torso"], pivots["torso"], (0, 0)),                        # torso encima, misma cintura
    ])
    return {
        "head": (pieces["head"], pivots["head"]),
        "body": (body, body_pv),
        "arm": (arm, arm_pv),
        "leg": (leg, leg_pv),
    }


def convert(src_dir, skin_name):
    meta_path = os.path.join(src_dir, "skin.json")
    meta = json.load(open(meta_path)) if os.path.exists(meta_path) else {"parts": {}}
    pieces, pivots = {}, {}
    for name in LEGACY_PIVOTS:
        pieces[name] = Image.open(os.path.join(src_dir, f"{name}.png")).convert("RGBA")
        info = meta["parts"].get(name)
        if info:
            assert abs(info["scale"] - 1.0 / ART_SCALE) < 1e-6, "se esperaba escala 1/ART_SCALE"
        pivots[name] = tuple(info["pivot"]) if info else LEGACY_PIVOTS[name]
    out_dir = os.path.join(ROOT, "assets/characters/skins", skin_name)
    write_skin(out_dir, compose_legacy(pieces, pivots), meta.get("name", skin_name))
    return out_dir


def write_skin(out_dir, parts, name, suffix=""):
    """Guarda {pieza: (imagen, punto de unión)} y actualiza skin.json."""
    os.makedirs(out_dir, exist_ok=True)
    meta_path = os.path.join(out_dir, "skin.json")
    meta = json.load(open(meta_path)) if os.path.exists(meta_path) else {}
    meta["name"] = meta.get("name", name)
    meta.setdefault("parts", {})
    for part, (img, (px, py)) in parts.items():
        img.save(os.path.join(out_dir, f"{part}{suffix}.png"))
        meta["parts"][f"{part}{suffix}"] = {"pivot": [round(px, 1), round(py, 1)],
                                            "scale": round(1.0 / ART_SCALE, 4)}
    with open(meta_path, "w") as fh:
        json.dump(meta, fh, indent=2, ensure_ascii=False)


if __name__ == "__main__":
    if len(sys.argv) == 4 and sys.argv[1] == "convert":
        src, name = sys.argv[2], sys.argv[3]
        tmp = None
        if os.path.abspath(src) == os.path.abspath(os.path.join(ROOT, "assets/characters/skins", name)):
            tmp = src.rstrip("/") + "_7piezas_tmp"
            shutil.copytree(src, tmp)
            src = tmp
        print("skin convertida →", os.path.relpath(convert(src, name), ROOT))
        if tmp:
            shutil.rmtree(tmp)
    else:
        print(__doc__)
