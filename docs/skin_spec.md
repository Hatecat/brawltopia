# Especificación de skins (personajes por piezas)

Un personaje se dibuja con **7 piezas**. El brazo y la pierna traseros reutilizan las mismas imágenes que los delanteros (el juego los oscurece), así que no hay que dibujarlos dos veces.

![Plantilla](skin_template.png)

## Reglas

- **Formato:** PNG con fondo transparente, una imagen por pieza, con estos nombres exactos.
- **Orientación:** de perfil, **mirando a la derecha**. Brazos y piernas **rectos y colgando hacia abajo**.
- **Extremos redondeados** en hombro, codo, cadera y rodilla: al girar, las piezas se superponen y la unión no debe notarse.
- **Punto de unión:** es donde gira la pieza. Debe quedar en la posición indicada (en la plantilla, el círculo celeste).
- **Resolución libre, proporción fija:** el juego escala cada imagen al tamaño de su pieza. Se recomienda 4× el tamaño del juego (columna "Arte recomendado"). Máximo 1024 px por lado.
- **Sin sombras proyectadas ni brillos externos:** solo la pieza, con su contorno.

## Piezas (personaje mediano)

| Archivo         | Qué es                                       | Juego (px) | Arte recomendado (px) | Punto de unión (arte) |
|-----------------|----------------------------------------------|-----------:|----------------------:|----------------------:|
| `head.png`      | Cabeza de perfil con cuello                  | 18 × 20    | 72 × 80               | (36, 72) cuello       |
| `torso.png`     | Tronco: pecho y abdomen                      | 24 × 28    | 96 × 112              | (48, 104) cintura     |
| `pelvis.png`    | Cadera / cinturón                            | 22 × 12    | 88 × 48               | (44, 8) cintura       |
| `upper_arm.png` | Brazo, de hombro a codo                      | 8 × 20     | 32 × 80               | (16, 16) hombro       |
| `forearm.png`   | Antebrazo con el puño cerrado abajo          | 8 × 20     | 32 × 80               | (16, 16) codo         |
| `thigh.png`     | Muslo, de cadera a rodilla                   | 10 × 24    | 40 × 96               | (20, 20) cadera       |
| `shin.png`      | Pierna con la zapatilla (punta a la derecha) | 12 × 26    | 48 × 104              | (20, 20) rodilla      |

Las coordenadas se miden desde la esquina superior izquierda. El personaje completo mide unos 80 px de alto en el juego, igual que su caja de colisión.

## Dónde van las skins

- **Del juego:** `res://assets/characters/skins/<nombre>/`. Por ejemplo, `default/`, que son las piezas provisorias.
- **De los jugadores:** `user://skins/<nombre>/`, en la carpeta de datos del usuario. Las piezas que falten o no sean válidas se reemplazan por las de `default`.

## Herramientas

- `tools/rig_spec.py`: la especificación en Python. Debe coincidir con `PART_SPECS` en `scripts/visuals/rig_visual.gd`.
- `tools/make_placeholder_skin.py`: dibuja las piezas provisorias y esta plantilla.
- `tools/make_rig_animations.py`: genera las animaciones del esqueleto.
