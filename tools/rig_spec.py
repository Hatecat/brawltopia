"""Especificación de las piezas del personaje (tamaño "mediano").

Debe coincidir con PART_SPECS en scripts/visuals/rig_visual.gd y con las
articulaciones de scenes/characters/visuals/rig_visual.tscn.

- size:  tamaño de la pieza en el juego, en píxeles.
- pivot: punto de unión (donde se engancha y gira la pieza), desde la esquina superior izquierda.
- Las imágenes se dibujan a ART_SCALE veces ese tamaño (más detalle); el juego las reduce.
- Todas las piezas miran a la DERECHA. Brazo y pierna se dibujan RECTOS, colgando hacia abajo.
- Cuerpo, brazo y pierna se deforman (se doblan) en una articulación interna:
  cintura, codo y rodilla. La cabeza es rígida.
"""
ART_SCALE = 4

PARTS = {
    #  nombre: (size,     pivot,    descripción)
    "head": ((18, 20), (9, 18),  "Cabeza de perfil con cuello. Unión: cuello, abajo al centro."),
    "body": ((24, 36), (12, 26), "Torso y cadera en una pieza. Unión: cintura (se dobla ahí)."),
    "arm":  ((8, 32),  (4, 4),   "Brazo completo, del hombro al puño, recto. Se dobla en el codo."),
    "leg":  ((12, 40), (5, 5),   "Pierna completa, de la cadera a la zapatilla, recta. Se dobla en la rodilla."),
}

# Distancia (px de juego) desde la unión hasta la articulación interna donde se dobla
# y dirección hacia la parte que gira (abajo = brazo/pierna, arriba = torso).
BEND = {
    "body": (0, "up"),     # la cintura es la misma unión
    "arm":  (12, "down"),  # hombro → codo
    "leg":  (14, "down"),  # cadera → rodilla
}

# Orden en la plantilla / en la hoja que se pide al generador de imágenes.
SHEET_ROWS = [["head", "body"], ["arm", "leg"]]


def art_size(name):
    (w, h), _, _ = PARTS[name]
    return w * ART_SCALE, h * ART_SCALE


def art_pivot(name):
    _, (x, y), _ = PARTS[name]
    return x * ART_SCALE, y * ART_SCALE
