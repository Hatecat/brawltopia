# Matías "Blue Rings" — personaje temporal

**Solo para pruebas.** Estas animaciones se recortaron automáticamente de la hoja de presentación `tmp_assets/gerald.jpg` (JPG de 800×533 px), así que tienen bordes irregulares y poca resolución. Se reemplazarán por el sistema de personajes por piezas.

| Archivo                  | Contenido                                              |
|--------------------------|--------------------------------------------------------|
| `idle.png`               | 7 cuadros, quieto                                      |
| `walk.png`               | 6 cuadros, caminando                                   |
| `jump.png`               | 6 cuadros, salto completo                              |
| `punch.png`              | 9 cuadros, fila "Puñetazos" completa                   |
| `kick.png`               | 8 cuadros, fila "Patadas" completa                     |
| `matias_frames.tres`     | Animaciones de Godot (generado por `make_frames.py`)   |
| `extract_from_sheet.py`  | Recorta las tiras desde la hoja (Python + Pillow + NumPy + SciPy) |
| `make_frames.py`         | Arma las animaciones eligiendo cuadros de cada tira    |

Todas las tiras usan celdas de 84×70 px. Quieto, caminar y salto se alinean por el centro de los pies; puñetazo y patada, por el pie de apoyo (trasero), para que el cuerpo no se deslice al golpear.

## Animaciones (cuadros de cada tira)

| Animación | Tira  | Cuadros            | Notas                                  |
|-----------|-------|--------------------|----------------------------------------|
| `idle`    | idle  | 0–6                | en bucle                               |
| `walk`    | walk  | 0–5                | en bucle                               |
| `jump`    | jump  | 1, 2               | subida                                 |
| `fall`    | jump  | 3                  | caída                                  |
| `punch`   | punch | 0, 4, 5, 5, 6      | golpe activo en los cuadros 2–3 de la animación |
| `kick`    | kick  | 1, 7, 5, 5, 7, 1   | patada alta; activo en los cuadros 2–3 |

Para cambiar qué cuadros usa cada animación, edita `ANIMS` en `make_frames.py` y ejecútalo: `python3 make_frames.py`.

Regenerar las tiras: `python3 extract_from_sheet.py ../../../tmp_assets/gerald.jpg . 26`
