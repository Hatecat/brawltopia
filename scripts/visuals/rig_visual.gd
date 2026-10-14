extends CharacterVisual
## Personaje por piezas: un esqueleto de articulaciones (Node2D) con una imagen
## por pieza (Sprite2D), animado con un AnimationPlayer.
##
## Las imágenes de las piezas forman una "skin" (un cosmético): una carpeta con
## head.png, torso.png, pelvis.png, upper_arm.png, forearm.png, thigh.png y shin.png.
## Puede estar dentro del juego (res://...) o en la carpeta del jugador (user://...).
## Especificación completa: docs/skin_spec.md

## Carpeta de la skin por defecto (se usa también si a otra skin le falta una pieza).
const DEFAULT_SKIN := "res://assets/characters/skins/default"

## Tamaño máximo aceptado por imagen de pieza, en píxeles (protege contra archivos enormes).
const MAX_IMAGE_SIZE := 1024

## Tamaño y punto de unión de cada pieza en el juego, en píxeles (personaje mediano).
## Debe coincidir con tools/rig_spec.py. Las imágenes pueden tener más resolución:
## se escalan a este tamaño, así que solo importan sus proporciones.
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

## Las extremidades traseras reutilizan las mismas imágenes, más oscuras para dar profundidad.
const BACK_TINT := Color(0.62, 0.62, 0.68)

## Skin que se carga al iniciar.
@export_dir var skin_path: String = DEFAULT_SKIN

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
	# Voltear todo el esqueleto: las piezas se dibujan mirando a la derecha.
	rig.scale.x = 1.0 if facing >= 0.0 else -1.0


## Carga una skin desde una carpeta. Las piezas que falten o no sean válidas
## se toman de la skin por defecto. Devuelve cuántas piezas se cargaron de la carpeta pedida.
func load_skin(path: String) -> int:
	var loaded := 0
	var textures := {}
	for part: String in PART_SPECS:
		var tex := _load_part_texture(path.path_join(part + ".png"))
		if tex:
			loaded += 1
		else:
			tex = _load_part_texture(DEFAULT_SKIN.path_join(part + ".png"))
		textures[part] = tex

	for sprite_path: String in SPRITE_PARTS:
		var sprite := get_node(sprite_path) as Sprite2D
		var part: String = SPRITE_PARTS[sprite_path]
		_fit_sprite(sprite, textures[part], PART_SPECS[part])
		if sprite_path.contains("Back"):
			sprite.self_modulate = BACK_TINT
	return loaded


## Ajusta una imagen a su pieza: la escala al tamaño de la pieza y la desplaza
## para que su punto de unión quede en el origen de la articulación.
func _fit_sprite(sprite: Sprite2D, tex: Texture2D, spec: Dictionary) -> void:
	sprite.texture = tex
	sprite.centered = false
	if tex == null:
		return
	var tex_size := Vector2(tex.get_size())
	var size: Vector2 = spec["size"]
	var pivot: Vector2 = spec["pivot"]
	sprite.scale = size / tex_size
	sprite.offset = -pivot / size * tex_size


## Lee una imagen de pieza. Solo acepta PNG de tamaño razonable.
## Devuelve null si no existe o no es válida.
func _load_part_texture(path: String) -> Texture2D:
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
	# Mipmaps: versiones reducidas de la imagen para que se vea suave al achicarla.
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
