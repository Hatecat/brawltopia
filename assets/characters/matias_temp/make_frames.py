"""Genera matias_frames.tres (SpriteFrames de Godot) a partir de las tiras PNG.

Cada animación elige qué cuadros de la tira usar y en qué orden.
Ejecutar desde esta carpeta: python3 make_frames.py
"""
RES = "res://assets/characters/matias_temp"
CELL_W, CELL_H = 84, 70

# nombre: (tira, cuadros, fps, loop)
ANIMS = {
    "idle": ("idle", [0, 1, 2, 3, 4, 5, 6], 8.0, True),
    "walk": ("walk", [0, 1, 2, 3, 4, 5], 10.0, True),
    "jump": ("jump", [1, 2], 8.0, False),
    "fall": ("jump", [3], 1.0, False),
    # guardia → carga → directo (x2, golpe activo) → guardia
    "punch": ("punch", [0, 4, 5, 5, 6], 14.0, False),
    # guardia → rodilla arriba → patada alta (x2, golpe activo) → rodilla → guardia
    "kick": ("kick", [1, 7, 5, 5, 7, 1], 12.0, False),
}

strips = sorted({a[0] for a in ANIMS.values()})
ext = [f'[ext_resource type="Texture2D" path="{RES}/{s}.png" id="{i + 1}_{s}"]' for i, s in enumerate(strips)]
subs, anims, used = [], [], set()
for name, (strip, frames, fps, loop) in ANIMS.items():
    refs = []
    for k in frames:
        sid = f"AtlasTexture_{strip}_{k}"
        if sid not in used:
            used.add(sid)
            subs.append(f'[sub_resource type="AtlasTexture" id="{sid}"]\n'
                        f'atlas = ExtResource("{strips.index(strip) + 1}_{strip}")\n'
                        f'region = Rect2({k * CELL_W}, 0, {CELL_W}, {CELL_H})\n')
        refs.append(f'{{\n"duration": 1.0,\n"texture": SubResource("{sid}")\n}}')
    anims.append('{\n"frames": [' + ", ".join(refs) + '],\n'
                 f'"loop": {"true" if loop else "false"},\n"name": &"{name}",\n"speed": {fps}\n}}')

out = (f'[gd_resource type="SpriteFrames" load_steps={len(ext) + len(subs) + 1} format=3]\n\n'
       + "\n".join(ext) + "\n\n" + "\n".join(subs)
       + "\n[resource]\nanimations = [" + ", ".join(anims) + "]\n")
open("matias_frames.tres", "w").write(out)
print(f"{len(ANIMS)} animaciones, {len(subs)} cuadros únicos")
