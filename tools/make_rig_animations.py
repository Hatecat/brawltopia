"""Genera las animaciones del esqueleto por piezas (AnimationLibrary de Godot).

Uso (desde la raíz del proyecto): python3 tools/make_rig_animations.py
Salida: assets/characters/rig/rig_animations.tres

Cada animación es una lista de poses clave (tiempo, ángulos en grados).
Convención de ángulos (personaje mirando a la derecha):
  - Brazos y piernas cuelgan hacia abajo en 0°. Negativo = hacia adelante.
  - Codo negativo = antebrazo hacia adelante/arriba. Rodilla positiva = doblez natural.
  - Torso y cabeza: positivo = inclinarse hacia adelante.
Las articulaciones que una pose no menciona vuelven a 0°.
La altura de la cadera se calcula sola para que el pie más bajo toque el suelo
(salvo en poses "en el aire").

Las duraciones de los ataques deben coincidir con total_frames / 60 de su AttackData.
"""
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets/characters/rig/rig_animations.tres")

JOINTS = {
    "torso": "Rig/Hips/Torso",
    "head": "Rig/Hips/Torso/Neck",
    "shoulder_f": "Rig/Hips/Torso/ShoulderFront",
    "elbow_f": "Rig/Hips/Torso/ShoulderFront/Elbow",
    "shoulder_b": "Rig/Hips/Torso/ShoulderBack",
    "elbow_b": "Rig/Hips/Torso/ShoulderBack/Elbow",
    "hip_f": "Rig/Hips/HipFront",
    "knee_f": "Rig/Hips/HipFront/Knee",
    "hip_b": "Rig/Hips/HipBack",
    "knee_b": "Rig/Hips/HipBack/Knee",
}
HIPS = "Rig/Hips"

# Geometría de la pierna (igual que rig_visual.tscn / rig_spec.py)
HIP_JOINT_Y = 3      # articulación de cadera bajo el centro de la cadera
THIGH_LEN = 14       # cadera → rodilla
SHIN_LEN = 21        # rodilla → planta del pie
AIR_HIPS_Y = -41     # altura de la cadera en el aire


def leg_drop(hip_deg, knee_deg):
    """Distancia vertical desde el centro de la cadera hasta la planta del pie."""
    a = math.radians(hip_deg)
    b = math.radians(hip_deg + knee_deg)
    return HIP_JOINT_Y + THIGH_LEN * math.cos(a) + SHIN_LEN * math.cos(b)


def hips_y(pose, air):
    if air:
        return AIR_HIPS_Y
    drop = max(leg_drop(pose.get("hip_f", 0), pose.get("knee_f", 0)),
               leg_drop(pose.get("hip_b", 0), pose.get("knee_b", 0)))
    return -round(drop, 2)


GUARD = dict(torso=6, head=-6, shoulder_f=-30, elbow_f=-110, shoulder_b=-18, elbow_b=-118,
             hip_f=-14, knee_f=12, hip_b=14, knee_b=8)


def pose(**changes):
    p = dict(GUARD)
    p.update(changes)
    return p


# nombre: (duración, loop, interpolación 1=lineal 2=cúbica, en_el_aire, [(tiempo, pose)])
ANIMS = {
    "idle": (1.0, True, 2, False, [
        (0.0, pose()),
        (0.5, pose(torso=8, head=-4, elbow_f=-104, elbow_b=-112, knee_f=18, knee_b=14, hip_f=-17, hip_b=11)),
        (1.0, pose()),
    ]),
    "walk": (0.6, True, 2, False, [
        (0.00, pose(hip_f=-26, knee_f=6, hip_b=22, knee_b=16, shoulder_f=-22, shoulder_b=-30)),
        (0.15, pose(hip_f=-4, knee_f=16, hip_b=4, knee_b=48, shoulder_f=-30, shoulder_b=-18)),
        (0.30, pose(hip_f=22, knee_f=16, hip_b=-26, knee_b=6, shoulder_f=-38, shoulder_b=-8)),
        (0.45, pose(hip_f=4, knee_f=48, hip_b=-4, knee_b=16, shoulder_f=-30, shoulder_b=-18)),
        (0.60, pose(hip_f=-26, knee_f=6, hip_b=22, knee_b=16, shoulder_f=-22, shoulder_b=-30)),
    ]),
    "jump": (0.2, False, 1, True, [
        (0.0, pose(hip_f=-50, knee_f=75, hip_b=8, knee_b=55, torso=10,
                   shoulder_f=-70, elbow_f=-80, shoulder_b=-50, elbow_b=-90)),
    ]),
    "fall": (0.2, False, 1, True, [
        (0.0, pose(hip_f=-25, knee_f=35, hip_b=12, knee_b=30, torso=2,
                   shoulder_f=-80, elbow_f=-40, shoulder_b=-60, elbow_b=-50)),
    ]),
    # Puñetazo: 20 cuadros de juego. Golpe activo en los cuadros 6-11.
    "punch": (20 / 60, False, 1, False, [
        (0 / 60, pose()),
        (5 / 60, pose(torso=0, shoulder_f=-18, elbow_f=-135, shoulder_b=-30)),
        (6 / 60, pose(torso=12, shoulder_f=-86, elbow_f=-4, shoulder_b=-20, elbow_b=-125, hip_f=-18, hip_b=18)),
        (12 / 60, pose(torso=12, shoulder_f=-86, elbow_f=-4, shoulder_b=-20, elbow_b=-125, hip_f=-18, hip_b=18)),
        (20 / 60, pose()),
    ]),
    # Patada: 28 cuadros de juego. Golpe activo en los cuadros 9-16.
    "kick": (28 / 60, False, 1, False, [
        (0 / 60, pose()),
        (6 / 60, pose(hip_f=-80, knee_f=95, torso=-4, hip_b=6, knee_b=10)),
        (9 / 60, pose(hip_f=-95, knee_f=0, torso=-16, head=4, hip_b=10, knee_b=6,
                      shoulder_f=-12, elbow_f=-100, shoulder_b=-40)),
        (16 / 60, pose(hip_f=-95, knee_f=0, torso=-16, head=4, hip_b=10, knee_b=6,
                       shoulder_f=-12, elbow_f=-100, shoulder_b=-40)),
        (21 / 60, pose(hip_f=-70, knee_f=85, torso=-4, hip_b=6, knee_b=10)),
        (28 / 60, pose()),
    ]),
}


def fmt(x):
    return ("%.6f" % x).rstrip("0").rstrip(".") if x != int(x) else str(int(x))


def track(i, path, times, values, interp, update=0):
    return (f'tracks/{i}/type = "value"\n'
            f'tracks/{i}/imported = false\n'
            f'tracks/{i}/enabled = true\n'
            f'tracks/{i}/path = NodePath("{path}")\n'
            f'tracks/{i}/interp = {interp}\n'
            f'tracks/{i}/loop_wrap = true\n'
            f'tracks/{i}/keys = {{\n'
            f'"times": PackedFloat32Array({", ".join(fmt(t) for t in times)}),\n'
            f'"transitions": PackedFloat32Array({", ".join("1" for _ in times)}),\n'
            f'"update": {update},\n'
            f'"values": [{", ".join(values)}]\n'
            f'}}\n')


subs, data = [], []
for name, (length, loop, interp, air, keys) in ANIMS.items():
    times = [t for t, _ in keys]
    body = [f'[sub_resource type="Animation" id="Animation_{name}"]',
            f'resource_name = "{name}"',
            f'length = {fmt(length)}']
    if loop:
        body.append("loop_mode = 1")
    tracks = []
    for i, (joint, path) in enumerate(JOINTS.items()):
        vals = [fmt(math.radians(p.get(joint, 0))) for _, p in keys]
        tracks.append(track(i, f"{path}:rotation", times, vals, interp))
    hy = [f"Vector2(0, {fmt(hips_y(p, air))})" for _, p in keys]
    tracks.append(track(len(JOINTS), f"{HIPS}:position", times, hy, interp))
    subs.append("\n".join(body) + "\n" + "".join(tracks))
    data.append(f'"{name}": SubResource("Animation_{name}")')

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w") as f:
    f.write(f'[gd_resource type="AnimationLibrary" load_steps={len(subs) + 1} format=3]\n\n')
    f.write("\n".join(subs))
    f.write("\n[resource]\n_data = {\n" + ",\n".join(data) + "\n}\n")
print(f"{len(ANIMS)} animaciones → {os.path.relpath(OUT, ROOT)}")
for name, (_, _, _, air, keys) in ANIMS.items():
    print(f"  {name:6s} cadera y: {[hips_y(p, air) for _, p in keys]}")
