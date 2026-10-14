"""Especificación de las piezas del personaje (tamaño "mediano").

Debe coincidir con PART_SPECS en scripts/visuals/rig_visual.gd.

- size:  tamaño de la pieza en el juego, en píxeles.
- pivot: punto de unión (donde gira la pieza), medido desde la esquina superior izquierda.
- Las imágenes se dibujan a ART_SCALE veces ese tamaño (más detalle); el juego las reduce.
- Todas las piezas miran a la DERECHA. Brazos y piernas se dibujan colgando hacia abajo.
"""
ART_SCALE = 4

PARTS = {
    #  nombre:     (size,      pivot,    descripción)
    "head":      ((18, 20), (9, 18),  "Cabeza de perfil mirando a la derecha. Unión: cuello, abajo al centro."),
    "torso":     ((24, 28), (12, 26), "Tronco (pecho y abdomen) de perfil. Unión: cintura, abajo al centro."),
    "pelvis":    ((22, 12), (11, 2),  "Cadera / cinturón. Unión: cintura, arriba al centro."),
    "upper_arm": ((8, 20),  (4, 4),   "Brazo (hombro a codo), colgando. Unión: hombro, arriba. Extremos redondeados."),
    "forearm":   ((8, 20),  (4, 4),   "Antebrazo con el puño cerrado abajo. Unión: codo, arriba."),
    "thigh":     ((10, 24), (5, 5),   "Muslo (cadera a rodilla), colgando. Unión: cadera, arriba. Extremos redondeados."),
    "shin":      ((12, 26), (5, 5),   "Pierna (rodilla a tobillo) con la zapatilla abajo apuntando a la derecha. Unión: rodilla, arriba."),
}

# Orden en la plantilla / en la hoja que se pide al generador de imágenes.
SHEET_ROWS = [["head", "torso", "pelvis"], ["upper_arm", "forearm", "thigh", "shin"]]


def art_size(name):
    (w, h), _, _ = PARTS[name]
    return w * ART_SCALE, h * ART_SCALE


def art_pivot(name):
    _, (x, y), _ = PARTS[name]
    return x * ART_SCALE, y * ART_SCALE
