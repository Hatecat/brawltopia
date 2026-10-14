extends CharacterVisual
## Personaje con dos vistas que se funden entre sí:
##   - Side (perfil): para moverse, saltar y atacar. Tiene todas las animaciones.
##   - Front (tres cuartos): para estar quieto, mirando más hacia la cámara.
##
## La vista de tres cuartos es opcional: se usa solo si la skin trae una carpeta
## "front/" con sus piezas. Si no, el personaje se ve siempre de perfil.

## Animaciones que se ven de tres cuartos (si la skin lo permite).
const FRONT_ANIMS: Array[StringName] = [&"idle"]
## Duración del fundido entre vistas, en segundos (se siente como un giro rápido).
const FADE_TIME := 0.1

## Skin que se carga al iniciar (carpeta de piezas; la vista de tres cuartos en <skin>/front).
@export_dir var skin_path: String = "res://assets/characters/skins/default"

## Animación pedida por última vez.
var current_animation: StringName = &""
## La skin actual trae vista de tres cuartos.
var has_front := false

var _front_weight := 0.0   # 0 = perfil, 1 = tres cuartos
var _front_target := 0.0

@onready var side: CharacterVisual = $Side
@onready var front: CharacterVisual = $Front


func _ready() -> void:
	load_skin(skin_path)


## Carga una skin en las dos vistas. Devuelve cuántas imágenes de perfil se cargaron.
func load_skin(path: String) -> int:
	var loaded: int = side.load_skin(path)
	torso_lift = side.torso_lift
	var front_dir := path.path_join("front")
	has_front = _has_head(front_dir)
	if has_front:
		front.load_skin(front_dir)
	else:
		_front_target = 0.0
	_apply_weight(true)
	return loaded


func play_animation(anim: StringName, restart: bool = false) -> void:
	current_animation = anim
	side.play_animation(anim, restart)   # el perfil anima siempre (queda debajo)
	var use_front := has_front and anim in FRONT_ANIMS
	if use_front:
		front.play_animation(anim, restart)
	_front_target = 1.0 if use_front else 0.0


func set_facing(facing: float) -> void:
	side.set_facing(facing)
	front.set_facing(facing)


## True si en este momento se ve (sobre todo) la vista de tres cuartos.
func is_showing_front() -> bool:
	return _front_weight > 0.5


func _process(delta: float) -> void:
	if _front_weight != _front_target:
		_front_weight = move_toward(_front_weight, _front_target, delta / FADE_TIME)
		_apply_weight(false)


func _apply_weight(instant: bool) -> void:
	if instant:
		_front_weight = _front_target
	# El perfil queda opaco debajo mientras la otra vista aparece o desaparece encima,
	# así nunca se ve el fondo a través del personaje.
	front.visible = _front_weight > 0.0
	front.modulate.a = _front_weight
	side.visible = _front_weight < 1.0


static func _has_head(dir: String) -> bool:
	var path := dir.path_join("head.png")
	if dir.begins_with("res://"):
		return ResourceLoader.exists(path)
	return FileAccess.file_exists(path)
