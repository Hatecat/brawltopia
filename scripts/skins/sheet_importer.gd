@tool
class_name SheetImporter
extends RefCounted
## Convierte una hoja de piezas sobre fondo magenta en una skin del juego.
##
## La hoja debe tener las 4 piezas separadas sobre magenta liso (#FF00FF), en dos filas:
##     arriba:  head, body
##     abajo:   arm, leg
## Resultado, en la carpeta de la skin:
##     <pieza>.png   pieza recortada con fondo transparente (o <pieza>_left.png para la hoja B)
##     skin.json     punto de unión y escala de cada pieza
##
## Funciona en el editor (panel "Skins", addons/skin_importer) y también dentro del juego
## (guardando en user://), para que los jugadores puedan importar sus propios cosméticos.
## Hace lo mismo que tools/import_parts_sheet.py, sin necesitar Python.

const RigVisualScript := preload("res://scripts/visuals/rig_visual.gd")

## Px de imagen por px de juego en las piezas guardadas (más detalle que el juego).
const ART_SCALE := 4.0
## Orden de las piezas en la hoja.
const SHEET_ROWS := [["head", "body"], ["arm", "leg"]]
## Para encontrar las piezas se trabaja con una versión reducida de la hoja (más rápido).
const LOW := 4
## Un grupo de píxeles cuenta como pieza si ocupa al menos esta fracción de la hoja.
const MIN_PIECE_FRACTION := 0.002
## Margen alrededor de cada pieza al recortarla, en px de la hoja.
const PAD := 4


## Importa una hoja. left_side = true para la hoja B (piezas mirando a la izquierda).
## Devuelve {"ok": bool, "message": String, "parts": {pieza: {"size", "pivot"}}}.
static func import_sheet(sheet: Image, skin_dir: String, left_side: bool = false) -> Dictionary:
	if sheet == null or sheet.is_empty():
		return _fail("No se pudo leer la imagen.")
	var img := sheet.duplicate() as Image
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)

	# 1. Quitar el fondo magenta (y marcar en una grilla reducida dónde hay pieza).
	var w := img.get_width()
	var h := img.get_height()
	var lw := ceili(float(w) / LOW)
	var lh := ceili(float(h) / LOW)
	var low := PackedByteArray()
	low.resize(lw * lh)
	img = _remove_magenta(img, low, lw)

	# 2. Separar las piezas: grupos de celdas conectadas en la grilla reducida.
	var labels := PackedInt32Array()
	labels.resize(lw * lh)
	var boxes := _find_pieces(low, labels, lw, lh)
	var expected := 0
	for row in SHEET_ROWS:
		expected += row.size()
	if boxes.size() != expected:
		return _fail("Se esperaban %d piezas y se encontraron %d. Revisa que estén separadas, que no haya texto ni manchas sueltas y que el fondo sea magenta liso." % [expected, boxes.size()])

	# 3. Ordenar en filas (por altura) y cada fila de izquierda a derecha.
	boxes.sort_custom(func(a, b): return a["center"].y < b["center"].y)
	var named := {}
	var i := 0
	for row in SHEET_ROWS:
		var row_boxes := boxes.slice(i, i + row.size())
		row_boxes.sort_custom(func(a, b): return a["center"].x < b["center"].x)
		for j in row.size():
			named[row[j]] = row_boxes[j]
		i += row.size()

	# 4. Recortar cada pieza, calcular su punto de unión y escala, y guardarla.
	DirAccess.make_dir_recursive_absolute(skin_dir)
	var meta := _read_meta(skin_dir)
	var suffix := "_left" if left_side else ""
	var result := {}
	for part: String in named:
		var piece := _cut_piece(img, named[part], labels, lw, lh)
		var pf := _pivot_and_factor(part, piece, left_side)
		var pivot: Vector2 = pf[0]
		var factor: float = pf[1]
		var size := Vector2i(maxi(1, roundi(piece.get_width() * factor)), maxi(1, roundi(piece.get_height() * factor)))
		piece.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
		var err := piece.save_png(skin_dir.path_join(part + suffix + ".png"))
		if err != OK:
			return _fail("No se pudo guardar %s (error %d)." % [part + suffix, err])
		var pv := (pivot * factor * 10.0).round() / 10.0
		meta["parts"][part + suffix] = {"pivot": [pv.x, pv.y], "scale": 1.0 / ART_SCALE}
		result[part + suffix] = {"size": size, "pivot": pv}
		# Las articulaciones se calculan con el cuerpo de la hoja A (mirando a la derecha).
		if part == "body" and (not left_side or not meta.has("joints")):
			meta["joints"] = estimate_joints(piece, pv)

	var f := FileAccess.open(skin_dir.path_join("skin.json"), FileAccess.WRITE)
	if f == null:
		return _fail("No se pudo escribir skin.json.")
	f.store_string(JSON.stringify(meta, "  "))
	f.close()
	return {"ok": true, "message": "Skin guardada en %s (%d piezas)." % [skin_dir, result.size()], "parts": result}


## Estima dónde van cuello, hombros y caderas a partir de la imagen del cuerpo
## (ya escalada a ART_SCALE px por px de juego) y su punto de unión (la cintura).
## Devuelve posiciones en px de juego, relativas a la cintura, para la sección "joints".
static func estimate_joints(body: Image, waist: Vector2) -> Dictionary:
	var h := float(body.get_height())
	var top := -waist.y / ART_SCALE                      # borde de arriba, en px de juego (negativo)
	var bottom := (h - waist.y) / ART_SCALE              # borde de abajo
	var to_game := func(span: Vector2) -> Array:
		# [centro, ancho] de una fila, en px de juego relativos a la cintura
		return [((span.x + span.y) / 2.0 - waist.x) / ART_SCALE, (span.y - span.x) / ART_SCALE]

	# Caderas: centradas bajo la cadera dibujada, separadas según su ancho.
	var hips: Array = to_game.call(_row_span(body, waist.y + bottom * ART_SCALE * 0.75))
	var hip_dx := clampf(hips[1] * 0.1, 1.5, 6.0)
	# Hombros y cuello: a la misma distancia del borde de arriba que en el esqueleto normal.
	var shoulder_y := top + 6.0
	var neck_y := top + 2.0
	var shoulders: Array = to_game.call(_row_span(body, waist.y + shoulder_y * ART_SCALE))
	var neck: Array = to_game.call(_row_span(body, waist.y + neck_y * ART_SCALE))
	var r := func(v: float) -> float: return snappedf(v, 0.1)
	return {
		"neck": [r.call(neck[0]), r.call(neck_y)],
		"shoulder_front": [r.call(shoulders[0] + 1.0), r.call(shoulder_y)],
		"shoulder_back": [r.call(shoulders[0] - 1.0), r.call(shoulder_y)],
		"hip_front": [r.call(hips[0] + hip_dx), 3.0],
		"hip_back": [r.call(hips[0] - hip_dx), 3.0],
	}


## Quita el magenta: el alfa depende de cuánto se parece cada píxel al color de fondo,
## y en los bordes se recupera el color real para que no quede un halo rosado.
static func _remove_magenta(img: Image, low: PackedByteArray, lw: int) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var key := _key_color(img)
	var data := img.get_data()
	for y in h:
		var row := y * w
		var low_row := (y / LOW) * lw
		for x in w:
			var o := (row + x) * 4
			var r := data[o]
			var g := data[o + 1]
			var b := data[o + 2]
			var magenta := mini(r, b) - g            # ~240 en el fondo, <= 0 en el personaje
			var a := clampf((200.0 - magenta) / 140.0, 0.0, 1.0)
			if a <= 0.02:
				data[o] = 0
				data[o + 1] = 0
				data[o + 2] = 0
				data[o + 3] = 0
				continue
			if a < 1.0:
				# El píxel es una mezcla: P = a*C + (1-a)*K  →  C = (P - (1-a)*K) / a
				data[o] = clampi(roundi((r - (1.0 - a) * key.x) / a), 0, 255)
				data[o + 1] = clampi(roundi((g - (1.0 - a) * key.y) / a), 0, 255)
				data[o + 2] = clampi(roundi((b - (1.0 - a) * key.z) / a), 0, 255)
			data[o + 3] = roundi(a * 255.0)
			if a > 0.5:
				low[low_row + x / LOW] = 1
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)


## Color del fondo: el promedio de las cuatro esquinas.
static func _key_color(img: Image) -> Vector3:
	var w := img.get_width() - 1
	var h := img.get_height() - 1
	var sum := Vector3.ZERO
	for p in [Vector2i(0, 0), Vector2i(w, 0), Vector2i(0, h), Vector2i(w, h)]:
		var c := img.get_pixelv(p)
		sum += Vector3(c.r8, c.g8, c.b8)
	return sum / 4.0


## Agrupa las celdas con pieza que están cerca (hasta 2 celdas de distancia).
## Devuelve una caja por pieza grande: {"id", "rect" (px de la hoja), "center"}.
static func _find_pieces(low: PackedByteArray, labels: PackedInt32Array, lw: int, lh: int) -> Array:
	var boxes: Array = []
	var next_id := 0
	var min_cells := int(lw * lh * MIN_PIECE_FRACTION)
	for start in low.size():
		if low[start] == 0 or labels[start] != 0:
			continue
		next_id += 1
		var queue := PackedInt32Array([start])
		labels[start] = next_id
		var head := 0
		var x0 := lw
		var y0 := lh
		var x1 := 0
		var y1 := 0
		while head < queue.size():
			var c := queue[head]
			head += 1
			var cx := c % lw
			var cy := c / lw
			x0 = mini(x0, cx); x1 = maxi(x1, cx)
			y0 = mini(y0, cy); y1 = maxi(y1, cy)
			for dy in range(-2, 3):
				var ny := cy + dy
				if ny < 0 or ny >= lh:
					continue
				for dx in range(-2, 3):
					var nx := cx + dx
					if nx < 0 or nx >= lw:
						continue
					var n := ny * lw + nx
					if low[n] == 1 and labels[n] == 0:
						labels[n] = next_id
						queue.append(n)
		if queue.size() >= min_cells:
			var rect := Rect2i(x0 * LOW, y0 * LOW, (x1 - x0 + 1) * LOW, (y1 - y0 + 1) * LOW)
			boxes.append({"id": next_id, "rect": rect, "center": Vector2(rect.get_center())})
	return boxes


## Recorta una pieza y borra los restos de otras piezas que caigan en su caja.
static func _cut_piece(img: Image, box: Dictionary, labels: PackedInt32Array, lw: int, lh: int) -> Image:
	var rect: Rect2i = box["rect"]
	rect = rect.grow(PAD).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var piece := img.get_region(rect)
	var id: int = box["id"]
	# Celdas de esta pieza, ensanchadas una celda (para no cortar el borde suave).
	var own := PackedByteArray()
	own.resize(lw * lh)
	for c in labels.size():
		if labels[c] == id:
			var cx := c % lw
			var cy := c / lw
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nx := cx + dx
					var ny := cy + dy
					if nx >= 0 and nx < lw and ny >= 0 and ny < lh:
						own[ny * lw + nx] = 1
	var pw := piece.get_width()
	var data := piece.get_data()
	for y in piece.get_height():
		var low_row := ((rect.position.y + y) / LOW) * lw
		for x in pw:
			if own[low_row + (rect.position.x + x) / LOW] == 0:
				var o := (y * pw + x) * 4
				data[o] = 0
				data[o + 1] = 0
				data[o + 2] = 0
				data[o + 3] = 0
	return Image.create_from_data(pw, piece.get_height(), false, Image.FORMAT_RGBA8, data)


## Punto de unión (px del recorte) y factor de escala hasta ART_SCALE px por px de juego.
static func _pivot_and_factor(part: String, piece: Image, facing_left: bool = false) -> Array:
	var h := piece.get_height()
	var spec: Dictionary = RigVisualScript.PART_SPECS[part]
	var size: Vector2 = spec["size"]
	var spec_pivot: Vector2 = spec["pivot"]
	if part == "arm" or part == "leg":
		# Extremidad recta: unión en el centro del extremo redondeado de arriba;
		# el largo desde la unión hasta el final (puño / planta) define la escala.
		var span := _row_span(piece, h * 0.08)
		var pivot := Vector2((span.x + span.y) / 2.0, (span.y - span.x) / 2.0)
		return [pivot, (size.y - spec_pivot.y) * ART_SCALE / (h - pivot.y)]
	if part == "head":
		# La cabeza se mide desde arriba hasta el cuello (no hasta la punta del pelo),
		# y la unión va en el centro del cuello.
		var top := _first_solid_row(piece)
		var neck := _find_neck(piece, facing_left)
		var length := float(neck["bottom"] - top + 1)
		var head_factor := size.y * ART_SCALE / length
		var pivot_y := top + length * spec_pivot.y / size.y
		# Centro del cuello un poco arriba del corte (si el corte es diagonal, la última
		# fila es solo una punta).
		var probe_y: float = neck["bottom"] - length * 0.05
		return [Vector2(_segment_near(piece, probe_y, neck["x"]), pivot_y), head_factor]
	# body: ajustar por alto; unión a la altura de la cintura.
	var factor := size.y * ART_SCALE / h
	var y := h * spec_pivot.y / size.y
	var span := _row_span(piece, minf(y, h * 0.97))
	return [Vector2((span.x + span.y) / 2.0, y), factor]


## Busca el cuello: recorre la cabeza de abajo hacia arriba y toma la primera forma
## que no esté en la parte de atrás. Lo que cuelga atrás (coleta, trenza, pelo largo)
## se ignora, porque el cuello siempre está bajo la cara. Devuelve {"bottom": fila, "x": centro}.
static func _find_neck(piece: Image, facing_left: bool) -> Dictionary:
	var used := piece.get_used_rect()
	var min_width := piece.get_width() * 0.06          # ignorar mechones finos
	for y in range(used.end.y - 1, used.position.y + int(used.size.y * 0.4), -1):
		var best_x := -1.0
		var best_front := -1.0
		for seg: Vector2 in _row_segments(piece, y):
			if seg.y - seg.x < min_width:
				continue
			var center := (seg.x + seg.y) / 2.0
			var front := (center - used.position.x) / used.size.x   # 0 = atrás, 1 = cara
			if facing_left:
				front = 1.0 - front
			if front >= 0.35 and front > best_front:
				best_front = front
				best_x = center
		if best_x >= 0.0:
			return {"bottom": y, "x": best_x}
	var span := _row_span(piece, used.end.y - 1)
	return {"bottom": used.end.y - 1, "x": (span.x + span.y) / 2.0}


## Centro del tramo de la fila y más cercano a x.
static func _segment_near(piece: Image, y: float, x: float) -> float:
	var best := x
	var best_dist := INF
	for seg: Vector2 in _row_segments(piece, y):
		var dist := 0.0 if (x >= seg.x and x <= seg.y) else minf(absf(seg.x - x), absf(seg.y - x))
		if dist < best_dist:
			best_dist = dist
			best = (seg.x + seg.y) / 2.0
	return best


## Primera fila con pieza (alfa > 50 %).
static func _first_solid_row(piece: Image) -> int:
	for y in piece.get_height():
		if not _row_segments(piece, y).is_empty():
			return y
	return 0


## Tramos continuos con pieza (alfa > 50 %) en una fila: [Vector2(inicio, fin), ...].
static func _row_segments(piece: Image, y: float) -> Array[Vector2]:
	var row := clampi(int(y), 0, piece.get_height() - 1)
	var segs: Array[Vector2] = []
	var start := -1
	for x in piece.get_width() + 1:
		var solid := x < piece.get_width() and piece.get_pixel(x, row).a > 0.5
		if solid and start < 0:
			start = x
		elif not solid and start >= 0:
			segs.append(Vector2(start, x))
			start = -1
	return segs


## Primera y última columna con pieza (alfa > 50 %) en una fila.
static func _row_span(piece: Image, y: float) -> Vector2:
	var row := clampi(int(y), 0, piece.get_height() - 1)
	var first := -1
	var last := -1
	for x in piece.get_width():
		if piece.get_pixel(x, row).a > 0.5:
			if first < 0:
				first = x
			last = x
	if first < 0:
		return Vector2(0, piece.get_width())
	return Vector2(first, last + 1)


static func _read_meta(dir: String) -> Dictionary:
	var meta := {}
	var path := dir.path_join("skin.json")
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary:
			meta = data
	if not meta.has("name"):
		meta["name"] = dir.get_file()
	if not meta.get("parts") is Dictionary:
		meta["parts"] = {}
	return meta


static func _fail(message: String) -> Dictionary:
	return {"ok": false, "message": message, "parts": {}}
