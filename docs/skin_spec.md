# Especificación de skins (personajes por piezas)

Un personaje se dibuja con **7 piezas**. Lo mínimo es una imagen de cada una mirando a la derecha. Con eso, el juego voltea las piezas al mirar a la izquierda y oscurece el brazo y la pierna traseros. Para personajes **asimétricos** (un tatuaje en un solo brazo, un parche en un ojo, una hombrera de un solo lado), se pueden agregar versiones opcionales.

![Plantilla](skin_template.png)

## Archivos de una skin

| Archivo                     | Obligatorio | Para qué                                                                 |
|-----------------------------|-------------|--------------------------------------------------------------------------|
| `<pieza>.png`               | sí          | La pieza mirando a la **derecha**.                                       |
| `<pieza>_left.png`          | no          | Cómo se ve la pieza cuando el personaje mira a la **izquierda**, dibujada mirando a la izquierda. Si no existe, se voltea la de la derecha. |
| `<pieza>_back.png`          | no          | Solo brazos y piernas: versión para la extremidad de atrás. Si no existe, se usa la de adelante oscurecida. |
| `<pieza>_back_left.png`     | no          | La extremidad de atrás, mirando a la izquierda.                          |
| `skin.json`                 | no          | Punto de unión y escala de cada imagen (lo genera el importador).        |

Las piezas son: `head`, `torso`, `pelvis`, `upper_arm`, `forearm`, `thigh` y `shin`.

**Ejemplo:** un personaje con un tatuaje en el brazo derecho. Mirando a la derecha, el brazo derecho es el de atrás, así que va en `upper_arm_back.png`. Mirando a la izquierda pasa a estar adelante, así que va en `upper_arm_left.png`.

## Reglas de dibujo

- **Formato:** PNG con fondo transparente. Máximo 1024 px por lado.
- **Orientación:** de perfil. Brazos y piernas **rectos y colgando hacia abajo**.
- **Extremos redondeados** en hombro, codo, cadera y rodilla: al girar, las piezas se superponen y la unión no debe notarse.
- **Sin sombras proyectadas ni brillos externos:** solo la pieza, con su contorno.

## Tamaños y puntos de unión (personaje mediano)

| Pieza       | Qué es                                       | Juego (px) | Arte recomendado (px) | Punto de unión (arte) |
|-------------|----------------------------------------------|-----------:|----------------------:|----------------------:|
| `head`      | Cabeza de perfil con cuello                  | 18 × 20    | 72 × 80               | (36, 72) cuello       |
| `torso`     | Tronco: pecho y abdomen                      | 24 × 28    | 96 × 112              | (48, 104) cintura     |
| `pelvis`    | Cadera / cinturón                            | 22 × 12    | 88 × 48               | (44, 8) cintura       |
| `upper_arm` | Brazo, de hombro a codo                      | 8 × 20     | 32 × 80               | (16, 16) hombro       |
| `forearm`   | Antebrazo con el puño cerrado abajo          | 8 × 20     | 32 × 80               | (16, 16) codo         |
| `thigh`     | Muslo, de cadera a rodilla                   | 10 × 24    | 40 × 96               | (20, 20) cadera       |
| `shin`      | Pierna con la zapatilla (punta adelante)     | 12 × 26    | 48 × 104              | (20, 20) rodilla      |

Las coordenadas se miden desde la esquina superior izquierda. El personaje completo mide unos 80 px de alto en el juego, igual que su caja de colisión.

## Dos formas de ajustar las piezas

1. **Con `skin.json`** (recomendado). Cada imagen indica su punto de unión (en px de la imagen) y su escala. El juego la escala **sin deformarla**, así que las proporciones pueden variar: un personaje puede tener la cabeza más grande o el torso más ancho.
   ```json
   {
     "name": "gerald",
     "parts": {
       "head": { "pivot": [30.6, 72.0], "scale": 0.25 },
       "head_left": { "pivot": [32.0, 72.0], "scale": 0.25 }
     }
   }
   ```
   El punto de unión de una imagen `_left` se mide en esa imagen, tal como está dibujada.
2. **Sin `skin.json`.** Cada imagen se estira hasta el tamaño de la tabla, y su punto de unión se ubica en la misma proporción. Sirve si se dibuja exactamente sobre la plantilla.

## Dónde van las skins

- **Del juego:** `res://assets/characters/skins/<nombre>/`. Por ejemplo, `default/` (piezas provisorias) y `gerald/`. Al exportar el juego hay que incluir `*.json` en los filtros de exportación (*Recursos → Filtros para exportar archivos que no son recursos*).
- **De los jugadores:** `user://skins/<nombre>/`, en la carpeta de datos del usuario. Las piezas que falten o no sean válidas se reemplazan por las de `default`.

## Herramientas

- `tools/import_parts_sheet.py <hoja.png> <nombre> [--side left]`: convierte una hoja de piezas sobre fondo magenta, como la que genera Copilot, en una skin con `skin.json`. Con `--side left` importa la hoja de las piezas mirando a la izquierda, como `<pieza>_left.png`.
- `tools/rig_spec.py`: la especificación en Python. Debe coincidir con `PART_SPECS` en `scripts/visuals/rig_visual.gd`.
- `tools/make_placeholder_skin.py`: dibuja las piezas provisorias y la plantilla.
- `tools/make_rig_animations.py`: genera las animaciones del esqueleto e informa dónde quedan el puño y el pie en cada golpe, para ubicar las hitboxes.
