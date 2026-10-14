# Prompt para generar las piezas con Copilot

## Antes de empezar

- **Adjunta `docs/skin_template.png`** junto con el prompt. Muestra la forma, el orden y la proporción de cada pieza, y ayuda mucho a que el generador respete el formato.
- **Fondo magenta, no transparente.** Los generadores de imágenes casi nunca producen transparencia real: suelen dibujar el patrón de cuadritos gris y blanco como si fuera parte de la imagen. Un fondo magenta liso (#FF00FF) se elimina de forma limpia y automática después.
- **No te preocupes por los tamaños exactos.** Basta con que las proporciones se parezcan. Al importar, cada pieza se recorta, se escala y se ajusta a su punto de unión.
- Genera varias veces y quédate con la hoja más **ordenada**: piezas separadas, sin sombras y sin texto. Descarga la imagen a la máxima resolución, sin capturas de pantalla ni JPG si es posible.

## Prompt (en inglés: los generadores suelen seguirlo mejor)

```
Create a 2D game character "cutout parts sheet" for a side-view fighting game, using the attached template as the layout guide.

CHARACTER: an adult man in his 30s, bald head, full dark brown beard, small blue hoop earring on the visible ear, athletic build. Wears a fitted plain black t-shirt, black track pants with a single white side stripe, and white sneakers.

STYLE: clean hand-drawn cartoon, flat colors with simple cel shading, bold dark outline of even thickness around every piece. No gradients on the background, no drop shadows, no glow, no text, no labels, no watermark.

VIEW: strict side profile, the character faces RIGHT. Every piece is drawn flat, with no perspective.

LAYOUT: one single image with a SOLID FLAT MAGENTA BACKGROUND (#FF00FF), filled edge to edge. Exactly 7 separate pieces, never touching or overlapping, with wide empty space between them, arranged in two rows:
- Top row, left to right: HEAD, TORSO, PELVIS.
- Bottom row, left to right: UPPER ARM, FOREARM, THIGH, SHIN.

PIECES:
1. HEAD: head in side profile facing right, including a short neck at the bottom.
2. TORSO: chest and belly in side view (t-shirt), no arms, no head, no legs. Rounded bottom edge.
3. PELVIS: hips and waistband of the pants only, short and wide, rounded.
4. UPPER ARM: from shoulder to elbow, perfectly straight and vertical, hanging down. Short t-shirt sleeve at the top, skin below. Both ends rounded like a capsule.
5. FOREARM: from elbow to a closed fist, perfectly straight and vertical, fist at the bottom. Top end rounded.
6. THIGH: from hip to knee, black track pants with the white stripe, perfectly straight and vertical. Both ends rounded like a capsule.
7. SHIN: from knee to ankle, black pants with the white stripe, perfectly straight and vertical, ending in a white sneaker at the bottom with the toe pointing RIGHT. Top end rounded.

PROPORTIONS (relative, same scale for all pieces): head 18 wide x 20 tall, torso 24 x 28, pelvis 22 x 12, upper arm 8 x 20, forearm 8 x 20, thigh 10 x 24, shin with sneaker 12 x 26. All pieces must be drawn at the same scale, as if cut from the same character.

Do not draw the assembled character. Draw only the 7 separate pieces on the magenta background.
```

## Si la hoja completa sale mal

Si el generador mezcla las piezas o dibuja el personaje armado, pídelas **una por una**, siempre con la misma descripción del personaje y el mismo estilo:

```
Same character and same style as before. Draw ONLY the [THIGH]: [from hip to knee, black track pants with a white side stripe, perfectly straight and vertical, both ends rounded like a capsule]. Side view, facing right. Single piece centered on a SOLID FLAT MAGENTA BACKGROUND (#FF00FF). No shadow, no text, no other body parts.
```

Cambia lo que está entre corchetes por la pieza que necesites, usando su descripción de la lista anterior.

## Personajes asimétricos (opcional)

Si el personaje tiene detalles de un solo lado (un tatuaje, un parche, una hombrera), pide una **segunda hoja** con las mismas piezas mirando a la izquierda. Agrega al principio del prompt:

```
Same character and same style as the previous sheet, but every piece faces LEFT (mirror view), showing the other side of the body. Keep the same layout and order.
```

## Después

Sube las imágenes a `tmp_assets/` en la rama `dev` y conviértelas en una skin:

```
python3 tools/import_parts_sheet.py tmp_assets/<hoja>.png <nombre>
python3 tools/import_parts_sheet.py tmp_assets/<hoja_izquierda>.png <nombre> --side left   (opcional)
```

El importador quita el magenta, separa las piezas, calcula el punto de unión y la escala de cada una y guarda la skin en `assets/characters/skins/<nombre>/`.
