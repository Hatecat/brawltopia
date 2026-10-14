extends CharacterVisual
## Personaje por piezas: un esqueleto de articulaciones (Node2D) con una imagen
## por pieza (Sprite2D), animado con un AnimationPlayer.
##
## Las imágenes de las piezas forman una "skin" (un cosmético): una carpeta con
## head.png, torso.png, pelvis.png, upper_arm.png, forearm.png, thigh.png y shin.png,
## y opcionalmente:
##   - <pieza>_left.png       cómo se ve la pieza mirando a la IZQUIERDA (dibujada así).
##                            Si no existe, se usa la de la derecha volteada.
##   - <pieza>_back.png       versión para el brazo/pierna de atrás (si no, se usa la de
##                            adelante oscurecida). También <pieza>_back_left.png.
##   - skin.json              punto de unión y escala de cada imagen (ver docs/skin_spec.md).
## Puede estar dentro del juego (res://...) o en la carpeta del jugador (user://...).

## Carpeta de la skin por defecto (se usa también si a otra skin le falta una pieza).
const DEFAULT_SKIN := "res://assets/characters/skins/default"

## Tamaño máximo aceptado por imagen de pieza, en píxeles (protege contra archivos enormes).
const MAX_IMAGE_SIZE := 1024

## Tamaño y punto de unión de cada pieza en el juego, en píxeles (personaje mediano).
## Debe coincidir con tools/rig_spec.py. Se usa cuando la skin no trae skin.json:
## entonces cada imagen se ajusta a este tamaño.
const PART_SPECS := {
	"head":      {"size": Vector2(18, 20), "pivot": Vector2(9, 18)},
	"torso":     {"size": Vector2(24, 28), "pivot": Vector2(12, 26)},
	"pelvis":    {"size": Vector2(22, 12), "pivot": Vector2(11, 2)},
	"upper_arm": {"size": Vector2(8, 20),  "pivot": Vector2(4, 4)},
	"forearm":   {"size": Vector2(8, 20),  "pivot": Vector2(4, 4)},
	"thigh":     {"size": Vector2(10, 24), "pivot": Vector2(5, 5)},
	"shin":      {"size": Vector2(12, 26), "pivot": Vector2(5, 5)},
}

## Qué pieza muestra cada Sprite2D del esqueleto.
const SPRITE_PARTS := {
	"Rig/Hips/Pelvis": "pelvis",
	"Rig/Hips/Torso/TorsoSprite": "torso",
	"Rig/Hips/Torso/Neck/Head": "head",
	"Rig/Hips/Torso/ShoulderFront/UpperArm": "upper_arm",
	"Rig/Hips/Torso/ShoulderFront/Elbow/Forearm": "forearm",
	"Rig/Hips/Torso/ShoulderBack/UpperArm": "upper_arm",
	"Rig/Hips/Torso/ShoulderBack/Elbow/Forearm": "forearm",
	"Rig/Hips/HipFront/Thigh": "thigh",
	"Rig/Hips/HipFront/Knee/Shin": "shin",
	"Rig/Hips/HipBack/Thigh": "thigh",
	"Rig/Hips/HipBack/Knee/Shin": "shin",
}

## Las extremidades traseras sin imagen propia se oscurecen para dar profundidad.
const BACK_TINT := Color(0.62, 0.62, 0.68)

## Skin que se carga al iniciar.
@export_dir var skin_path: String = DEFAULT_SKIN

## Cómo se dibuja cada Sprite2D según el lado: {"right"/"left": {ruta: {texture, scale, offset, tint}}}
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
	for sprite_path: String in SPRITE_PARTS:
		var part: String = SPRITE_PARTS[sprite_path]
		var is_back := sprite_path.contains("Back")
		for side: String in ["right", "left"]:
			var look := {}
			for candidate: String in _candidates(part, is_back, side == "left"):
				look = _make_look(path, candidate, part, meta, cache)
				if not look.is_empty():
					used[candidate] = true
					break
			if look.is_empty():
				look = _make_look(DEFAULT_SKIN, part, part, default_meta, cache)
			# Atrás sin imagen propia: oscurecer.
			look["tint"] = BACK_TINT if is_back and not look.get("file", "").contains("_back") else Color.WHITE
			_looks[side][sprite_path] = look
	_apply_looks()
	return used.size()


## Nombres de archivo a probar, en orden de preferencia.
func _candidates(part: String, is_back: bool, left: bool) -> Array[String]:
	var list: Array[String] = []
	if left:
		if is_back:
			list.append(part + "_back_left")
		list.append(part + "_left")
	if is_back:
		list.append(part + "_back")
	list.append(part)
	return list


## Prepara cómo se dibuja una imagen: textura, escala y desplazamiento para que
## su punto de unión quede en la articulación. Vacío si la imagen no existe o no es válida.
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
	if file.ends_with("_left"):
		# Dibujada mirando a la izquierda: la volteamos para que el esqueleto
		# (que se voltea al mirar a la izquierda) la muestre tal como se dibujó.
		tex_image.flip_x()
		pivot.x = size.x - pivot.x
	tex_image.generate_mipmaps()  # versiones reducidas: se ve suave al achicarla
	return {
		"texture": ImageTexture.create_from_image(tex_image),
		"scale": scale_v,
		"offset": -pivot,
		"file": file,
	}


func _apply_looks() -> void:
	for sprite_path: String in _looks[_side]:
		var look: Dictionary = _looks[_side][sprite_path]
		var sprite := get_node(sprite_path) as Sprite2D
		sprite.centered = false
		sprite.texture = look.get("texture")
		sprite.scale = look.get("scale", Vector2.ONE)
		sprite.offset = look.get("offset", Vector2.ZERO)
		sprite.self_modulate = look.get("tint", Color.WHITE)


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
