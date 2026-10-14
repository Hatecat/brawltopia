extends CharacterVisual
## Personaje por piezas con deformación por malla.
##
## Un esqueleto de articulaciones (Node2D) animado con un AnimationPlayer mueve 4 imágenes:
##   - head: rígida, gira en el cuello (Sprite2D).
##   - body, arm, leg: mallas (DeformMesh) que se DOBLAN en la cintura, el codo y la
##     rodilla, así la imagen se curva entera en vez de partirse en dos.
## El brazo y la pierna de atrás reutilizan imágenes, oscurecidas.
##
## Una "skin" es una carpeta con head.png, body.png, arm.png y leg.png, y opcionalmente:
##   - <pieza>_left.png       el OTRO lado del cuerpo, dibujado mirando a la izquierda
##                            (un tatuaje, una rodillera...). Si no existe, se voltea la normal.
##   - <pieza>_back.png       brazo/pierna de atrás con imagen propia (rara vez hace falta).
##   - skin.json              punto de unión y escala de cada imagen (ver docs/skin_spec.md).
## Puede estar dentro del juego (res://...) o en la carpeta del jugador (user://...).
##
## Qué lado se ve: mirando a la derecha se ve el lado IZQUIERDO del personaje
## (<pieza>.png); mirando a la izquierda, el DERECHO (<pieza>_left.png). La extremidad
## de atrás es siempre la del otro lado, así un detalle de un solo lado queda en su lugar.

## Carpeta de la skin por defecto (se usa también si a otra skin le falta una pieza).
const DEFAULT_SKIN := "res://assets/characters/skins/default"

## Tamaño máximo aceptado por imagen de pieza, en píxeles (protege contra archivos enormes).
const MAX_IMAGE_SIZE := 1024

## Tamaño y punto de unión de cada pieza en el juego, en píxeles (personaje mediano).
## Debe coincidir con tools/rig_spec.py. Se usa cuando la skin no trae skin.json:
## entonces cada imagen se ajusta a este tamaño.
const PART_SPECS := {
	"head": {"size": Vector2(18, 20), "pivot": Vector2(9, 18)},
	"body": {"size": Vector2(24, 36), "pivot": Vector2(12, 26)},
	"arm":  {"size": Vector2(8, 32),  "pivot": Vector2(4, 4)},
	"leg":  {"size": Vector2(12, 40), "pivot": Vector2(5, 5)},
}

## Qué pieza muestra cada nodo del esqueleto.
const PART_NODES := {
	"Rig/Hips/Body": "body",
	"Rig/Hips/Torso/Neck/Head": "head",
	"Rig/Hips/Torso/ShoulderFront/Arm": "arm",
	"Rig/Hips/Torso/ShoulderBack/Arm": "arm",
	"Rig/Hips/HipFront/Leg": "leg",
	"Rig/Hips/HipBack/Leg": "leg",
}

## Las extremidades traseras se oscurecen para dar profundidad.
const BACK_TINT := Color(0.62, 0.62, 0.68)

## Skin que se carga al iniciar.
@export_dir var skin_path: String = DEFAULT_SKIN

## Cómo se dibuja cada pieza según el lado: {"right"/"left": {ruta: {texture, scale, pivot, tint}}}
var _looks := {"right": {}, "left": {}}
var _side := "right"

@onready var rig: Node2D = $Rig
@onready var anim_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	load_skin(skin_path)


func play_animation(anim: StringName, restart: bool = false) -> void:
	if not anim_player.has_animation(anim):
		push_warning("RigVisual: no existe la animación '%s'" % anim)
		return
	if restart or anim_player.current_animation != anim:
		anim_player.play(anim)
		anim_player.seek(0.0, true)


func set_facing(facing: float) -> void:
	# Voltear todo el esqueleto (las piezas se dibujan mirando a la derecha)
	# y usar las imágenes del lado correspondiente.
	rig.scale.x = 1.0 if facing >= 0.0 else -1.0
	var side := "right" if facing >= 0.0 else "left"
	if side != _side:
		_side = side
		_apply_looks()


## Carga una skin desde una carpeta. Las piezas que falten o no sean válidas
## se toman de la skin por defecto. Devuelve cuántas imágenes se cargaron de la carpeta pedida.
func load_skin(path: String) -> int:
	var meta := _read_meta(path)
	var default_meta := _read_meta(DEFAULT_SKIN)
	var cache := {}   # archivo → Image (para no leer dos veces la misma imagen)
	var used := {}
	for node_path: String in PART_NODES:
		var part: String = PART_NODES[node_path]
		var is_back := node_path.contains("Back")
		for side: String in ["right", "left"]:
			var look := {}
			for candidate: String in _candidates(part, is_back, side == "left"):
				look = _make_look(path, candidate, part, meta, cache)
				if not look.is_empty():
					used[candidate] = true
					break
			if look.is_empty():
				look = _make_look(DEFAULT_SKIN, part, part, default_meta, cache)
			look["tint"] = BACK_TINT if is_back else Color.WHITE
			_looks[side][node_path] = look
	_apply_looks()
	return used.size()


## Nombres de archivo a probar, en orden de preferencia.
## <pieza>.png muestra el lado izquierdo del cuerpo; <pieza>_left.png, el derecho.
## La extremidad de atrás es la del lado contrario al que se ve.
func _candidates(part: String, is_back: bool, left: bool) -> Array[String]:
	if not left and not is_back:
		return [part]                                       # mirando a la der.: lado izquierdo
	if left and not is_back:
		return [part + "_left", part]                       # mirando a la izq.: lado derecho
	if not left and is_back:
		return [part + "_back", part + "_left", part]       # atrás, mirando a la der.: lado derecho
	return [part + "_back_left", part]                      # atrás, mirando a la izq.: lado izquierdo


## Prepara cómo se dibuja una imagen: textura, escala y punto de unión.
## Vacío si la imagen no existe o no es válida.
func _make_look(dir: String, file: String, part: String, meta: Dictionary, cache: Dictionary) -> Dictionary:
	var key := dir.path_join(file + ".png")
	if not cache.has(key):
		cache[key] = _load_part_image(key)
	var image: Image = cache[key]
	if image == null:
		return {}
	var size := Vector2(image.get_size())
	var scale_v: Vector2
	var pivot: Vector2
	var info: Dictionary = meta.get("parts", {}).get(file, {})
	if info.has("pivot") and info.has("scale"):
		# Con skin.json: escala uniforme (la imagen no se deforma).
		pivot = Vector2(info["pivot"][0], info["pivot"][1])
		scale_v = Vector2.ONE * float(info["scale"])
	else:
		# Sin skin.json: ajustar la imagen a la caja de la pieza.
		var spec: Dictionary = PART_SPECS[part]
		scale_v = spec["size"] / size
		pivot = spec["pivot"] / spec["size"] * size
	var tex_image := image.duplicate() as Image  # copia: la original queda en caché sin modificar
	if file.contains("_left"):
		# Dibujada mirando a la izquierda: la volteamos para que el esqueleto
		# (que se voltea al mirar a la izquierda) la muestre tal como se dibujó.
		tex_image.flip_x()
		pivot.x = size.x - pivot.x
	tex_image.generate_mipmaps()  # versiones reducidas: se ve suave al achicarla
	return {
		"texture": ImageTexture.create_from_image(tex_image),
		"scale": scale_v,
		"pivot": pivot,
		"file": file,
	}


func _apply_looks() -> void:
	for node_path: String in _looks[_side]:
		var look: Dictionary = _looks[_side][node_path]
		var node := get_node(node_path)
		var tex: Texture2D = look.get("texture")
		var scale_v: Vector2 = look.get("scale", Vector2.ONE)
		var pivot: Vector2 = look.get("pivot", Vector2.ZERO)
		if node is DeformMesh:
			(node as DeformMesh).setup(tex, pivot, scale_v)
		elif node is Sprite2D:
			var sprite := node as Sprite2D
			sprite.centered = false
			sprite.texture = tex
			sprite.scale = scale_v
			sprite.offset = -pivot
		(node as CanvasItem).self_modulate = look.get("tint", Color.WHITE)


func _read_meta(dir: String) -> Dictionary:
	var path := dir.path_join("skin.json")
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


## Lee una imagen de pieza. Solo acepta PNG de tamaño razonable.
## Devuelve null si no existe o no es válida.
func _load_part_image(path: String) -> Image:
	var image: Image
	if path.begins_with("res://"):
		# Dentro del juego las imágenes están importadas por Godot.
		if not ResourceLoader.exists(path):
			return null
		var imported := load(path) as Texture2D
		if imported == null:
			return null
		image = imported.get_image()
	else:
		# Fuera del juego (skins de jugadores): leer el PNG directamente.
		if path.get_extension().to_lower() != "png" or not FileAccess.file_exists(path):
			return null
		image = Image.load_from_file(path)

	if image == null or image.is_empty():
		push_warning("RigVisual: imagen no válida: " + path)
		return null
	if image.get_width() > MAX_IMAGE_SIZE or image.get_height() > MAX_IMAGE_SIZE:
		push_warning("RigVisual: imagen demasiado grande (máx %d px): %s" % [MAX_IMAGE_SIZE, path])
		return null
	if image.is_compressed():
		image.decompress()
	if image.has_mipmaps():
		image.clear_mipmaps()
	return image
