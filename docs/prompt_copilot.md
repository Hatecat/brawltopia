# Prompt para generar las piezas con Copilot

El personaje se arma con **4 piezas**: cabeza, cuerpo (torso + cadera), brazo completo y pierna completa. Brazo y pierna se doblan en el juego (codo y rodilla), así que se dibujan **rectos y enteros**.

## Antes de empezar

- **Adjunta las imágenes de referencia** que se indican en cada prompt. La plantilla (`docs/skin_template.png`) muestra forma, orden y proporción de las piezas.
- **Fondo magenta, no transparente.** Los generadores casi nunca producen transparencia real; un magenta liso (#FF00FF) se elimina limpio después.
- **No importan los tamaños exactos,** solo las proporciones. El importador ajusta cada pieza.
- Genera varias veces y quédate con la hoja más **ordenada**: 4 piezas separadas, sin sombras ni texto.

## Personajes asimétricos: dos hojas

Mirando a la derecha se ve el **lado izquierdo** del personaje; mirando a la izquierda, el **derecho**. Si hay detalles de un solo lado, se piden dos hojas:

| Hoja | Mira hacia | Muestra | Se importa como |
|------|------------|---------|-----------------|
| A    | derecha    | lado izquierdo: brazo y pierna izquierdos | `<pieza>.png` |
| B    | izquierda  | lado derecho: brazo y pierna derechos     | `<pieza>_left.png` |

El brazo y la pierna de atrás se toman de la otra hoja, así que cada detalle queda siempre en su lado.

---

## Gerald: hoja A (lado izquierdo, con la rodillera)

Adjunta: `tmp_assets/Designer-gerald.png` (apariencia y estilo) y `docs/skin_template.png` (piezas).

```
I am attaching two images:
- IMAGE 1: the existing cutout parts of this character. Use it as the exact reference for his appearance, colors, outline and drawing style.
- IMAGE 2: a layout template. Use it ONLY for the list, order and proportions of the 4 pieces. Ignore its drawing style, colors, text labels and colored circles. Do not copy any text.

TASK: draw a 2D game "cutout parts sheet" of this character in strict side profile, FACING RIGHT, showing his LEFT side. The arm is his LEFT arm and the leg is his LEFT leg.

CHARACTER: adult man in his 30s, bald head, full dark brown beard, small blue hoop earring on the visible ear, athletic build. Fitted plain black t-shirt, black track pants with a single white side stripe, white sneakers.
LEFT LEG INJURY: he is recovering from a knee injury, so his LEFT knee wears a sports knee brace: a dark gray hinged brace with black velcro straps above and below the knee, worn over the pants.

STYLE: clean hand-drawn cartoon, flat colors with simple cel shading, bold dark outline of even thickness around every piece. No drop shadows, no glow, no text, no labels, no watermark.

LAYOUT: one single image with a SOLID FLAT MAGENTA BACKGROUND (#FF00FF), filled edge to edge. Exactly 4 separate pieces, never touching or overlapping, with wide empty space between them, in two rows:
- Top row, left to right: HEAD, BODY.
- Bottom row, left to right: ARM, LEG.

PIECES (all facing RIGHT, flat, no perspective):
1. HEAD: head in side profile, including a short neck at the bottom.
2. BODY: torso and hips as ONE piece: the t-shirt on top and the waistband and hips of the pants below it. No arms, no head, no legs. Neck opening at the top, rounded hips at the bottom.
3. ARM: the WHOLE arm from shoulder to closed fist as ONE piece, perfectly straight and vertical, hanging down, never bent. Short t-shirt sleeve at the top, skin below, fist at the bottom. Rounded top end. Keep a similar width around the elbow.
4. LEG: the WHOLE leg from hip to sneaker as ONE piece, perfectly straight and vertical, never bent. Black track pants with the white side stripe, the knee brace on the knee, and a white sneaker at the bottom with the toe pointing RIGHT. Rounded top end. Keep a similar width around the knee.

PROPORTIONS (relative, same scale for all pieces): head 18 wide x 20 tall, body 24 x 36, arm 8 x 32, leg 12 x 40.

Do not draw the assembled character. Draw only the 4 separate pieces on the magenta background.
```

## Gerald: hoja B (lado derecho, con el tatuaje de dragón)

Adjunta: el resultado de la **hoja A** (para que sea el mismo personaje) y `docs/skin_template.png`.

```
I am attaching two images:
- IMAGE 1: the cutout parts sheet of this character seen from his LEFT side. Use it as the exact reference for his appearance, colors, outline, drawing style, scale and layout.
- IMAGE 2: a layout template. Use it ONLY for the list, order and proportions of the 4 pieces. Ignore its drawing style, colors, text labels and colored circles. Do not copy any text.

TASK: draw the same 4 cutout pieces of the same character, but now seen from his RIGHT side: every piece FACES LEFT. The arm is his RIGHT arm and the leg is his RIGHT leg. Do NOT simply mirror image 1: this side of his body has different details.

DIFFERENCES ON HIS RIGHT SIDE:
- HEAD: a black ink DRAGON TATTOO on the right side of his bald head, coiling from above the ear toward the back of the skull. Same blue hoop earring on this ear.
- LEG: NO knee brace on this leg (the injury is only on his left knee). Plain black track pants with the white side stripe.
- Everything else matches image 1.

STYLE: identical to image 1: clean hand-drawn cartoon, flat colors with simple cel shading, bold dark outline of even thickness. No drop shadows, no glow, no text, no labels, no watermark.

LAYOUT: one single image with a SOLID FLAT MAGENTA BACKGROUND (#FF00FF), filled edge to edge. Exactly 4 separate pieces, never touching or overlapping, with wide empty space between them, in two rows:
- Top row, left to right: HEAD, BODY.
- Bottom row, left to right: ARM, LEG.

PIECES (all facing LEFT, flat, no perspective):
1. HEAD: head in side profile facing left, including a short neck at the bottom.
2. BODY: torso and hips as ONE piece (t-shirt on top, pants waistband and hips below). No arms, no head, no legs.
3. ARM: the WHOLE right arm from shoulder to closed fist, perfectly straight and vertical, hanging down, never bent. Short sleeve at the top, fist at the bottom.
4. LEG: the WHOLE right leg from hip to sneaker, perfectly straight and vertical, never bent, white sneaker at the bottom with the toe pointing LEFT.

Same scale and proportions as image 1. Do not draw the assembled character. Draw only the 4 separate pieces on the magenta background.
```

## Si sale mal

- **Mezcla piezas o dibuja al personaje armado:** pídelas de a una, con la misma descripción y estilo, y "single piece centered on a SOLID FLAT MAGENTA BACKGROUND (#FF00FF)".
- **Dobla el brazo o la pierna:** repite "perfectly straight and vertical, never bent". Una extremidad doblada en la imagen no se puede enderezar después.
- **Agrega texto o manchas:** regenera, o pinta encima con el mismo magenta en un editor de imágenes.

## Después

Sube las hojas a `tmp_assets/` en la rama `dev` y conviértelas en una skin:

```
python3 tools/import_parts_sheet.py tmp_assets/<hoja_A>.png gerald
python3 tools/import_parts_sheet.py tmp_assets/<hoja_B>.png gerald --side left
```

El importador quita el magenta, separa las 4 piezas, calcula el punto de unión y la escala de cada una y guarda la skin en `assets/characters/skins/<nombre>/`. Ver `docs/skin_spec.md`.
