# Matías "Blue Rings" — personaje temporal

**Solo para pruebas.** Estas animaciones se recortaron automáticamente de la hoja de presentación `tmp_assets/gerald.jpg` (JPG de 800×533 px), así que tienen bordes irregulares y poca resolución. Se reemplazarán por el sistema de personajes por piezas.

| Archivo                  | Contenido                                              |
|--------------------------|--------------------------------------------------------|
| `idle.png`               | 7 cuadros, quieto                                      |
| `walk.png`               | 6 cuadros, caminando                                   |
| `jump.png`               | 6 cuadros, salto completo                              |
| `matias_frames.tres`     | Animaciones de Godot: `idle`, `walk`, `jump` (cuadros 2–3 del salto), `fall` (cuadro 4) |
| `extract_from_sheet.py`  | Script que hizo el recorte (Python + Pillow + NumPy + SciPy) |

Todas las tiras usan celdas de 78×68 px con los pies centrados abajo, para que el personaje no se desplace al cambiar de animación.

Regenerar: `python3 extract_from_sheet.py ../../../tmp_assets/gerald.jpg . 26`
