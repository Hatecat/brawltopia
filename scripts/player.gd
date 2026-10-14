extends CharacterBody2D
## Luchador: movimiento, salto, agacharse, gravedad, ataques y reacción a los golpes.
## Puede controlarlo el jugador (teclado) o quedarse quieto como muñeco de práctica.
##
## CharacterBody2D no se mueve solo: cada frame de física calculamos
## `velocity` y llamamos a move_and_slide(), que mueve el cuerpo,
## lo detiene al chocar y actualiza is_on_floor().
##
## El dibujo vive aparte (un CharacterVisual). Este script solo le pide
## "reproduce tal animación" y "mira hacia tal lado".

## Se emite cuando un ataque toca la hurtbox de otro personaje.
signal hit_landed(target: Area2D, attack: AttackData)
## Se emite cuando este luchador recibe un golpe.
signal got_hit(attack: AttackData)

# --- Parámetros ajustables desde el Inspector (@export) ---
@export var move_speed: float = 420.0      ## Velocidad horizontal máxima (px/s).
@export var acceleration: float = 3200.0   ## Qué tan rápido alcanza move_speed.
@export var air_acceleration: float = 1800.0  ## Control en el aire (menor que en el suelo).
@export var friction: float = 2800.0       ## Qué tan rápido frena al soltar.
@export var jump_velocity: float = -900.0  ## Impulso del salto (negativo = hacia arriba).

## Si es false, no lee el teclado: sirve como muñeco de práctica.
@export var player_controlled: bool = true
## Hacia dónde mira al empezar: 1 = derecha, -1 = izquierda.
@export var start_facing: float = 1.0

## Escena que dibuja al personaje (debe heredar de CharacterVisual).
@export var visual_scene: PackedScene
## Skin (carpeta de piezas) para visuales por piezas. Vacío = la del visual.
@export_dir var skin_path: String = ""

@export_group("Empuje entre luchadores")
## Distancia mínima entre dos luchadores (px). Si se acercan más, se empujan: no se
## pueden atravesar caminando, pero sí saltar por encima.
@export var push_distance: float = 34.0
## Si la diferencia de altura entre los dos es mayor que esto (px), no se empujan
## (uno pasa por encima del otro en un salto).
@export var push_height: float = 70.0

@export_group("Hurtbox")
@export var stand_hurtbox_size: Vector2 = Vector2(40, 80)   ## Zona golpeable de pie.
@export var crouch_hurtbox_size: Vector2 = Vector2(44, 60)  ## Zona golpeable agachado.

@export_group("Ataques")
@export var punch_attack: AttackData         ## De pie + "punch".
@export var kick_attack: AttackData          ## De pie + "kick".
@export var crouch_punch_attack: AttackData  ## Agachado + "punch".
@export var crouch_kick_attack: AttackData   ## Agachado + "kick".
@export var air_punch_attack: AttackData     ## En el aire + "punch".
@export var air_kick_attack: AttackData      ## En el aire + "kick".

# La gravedad se lee de Project Settings > Physics > 2D > Default Gravity,
# así todos los objetos del juego comparten el mismo valor.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

## Hacia dónde mira: 1 = derecha, -1 = izquierda.
var facing: float = 1.0

## Está agachado (solo en el suelo, mientras se mantiene "crouch").
var is_crouching: bool = false

## Ataque en curso, o null si no está atacando.
var current_attack: AttackData = null

## Cuadro de juego actual del ataque en curso (0 = el cuadro en que empezó).
var attack_frame: int = 0

## Cuadros de juego que le quedan aturdido tras recibir un golpe (0 = puede actuar).
var hitstun_left: int = 0
## Daño acumulado (como el porcentaje de Smash; por ahora solo se cuenta).
var damage_taken: float = 0.0

## El dibujo del personaje (se crea en _ready a partir de visual_scene).
var visual: CharacterVisual

# Hurtboxes ya golpeadas en este ataque (para no golpear dos veces lo mismo).
var _already_hit: Array[Area2D] = []

@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D


func _ready() -> void:
	add_to_group("fighters")  # la cámara de pelea encuadra a este grupo
	facing = signf(start_facing) if start_facing != 0.0 else 1.0
	if visual_scene:
		visual = visual_scene.instantiate() as CharacterVisual
		add_child(visual)
		move_child(visual, 0)  # que se dibuje antes (debajo) de las cajas de depuración
		if skin_path != "" and visual.has_method("load_skin"):
			visual.load_skin(skin_path)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	_update_hurtbox()


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	var on_floor := is_on_floor()

	if hitstun_left > 0:
		# Aturdido: no puede moverse ni atacar; solo sale despedido y frena al tocar el suelo.
		hitstun_left -= 1
		if on_floor:
			_brake(delta)
		_update_hurtbox()
		move_and_slide()
		_push_away_from_fighters()
		return

	if current_attack:
		_update_attack(on_floor)
	else:
		is_crouching = on_floor and _pressed("crouch")
		_handle_attack_input(on_floor)

	if current_attack == null:
		_handle_jump()
		if is_crouching:
			_brake(delta)  # agachado no camina
		else:
			_handle_horizontal_movement(delta, true)
	elif current_attack.aerial:
		_handle_horizontal_movement(delta, false)  # en el aire se mueve, pero no se gira
	else:
		_brake(delta)  # en el suelo, atacando no se mueve

	_update_hurtbox()
	move_and_slide()
	_push_away_from_fighters()
	_update_animation()


func _apply_gravity(delta: float) -> void:
	# En el aire acumulamos velocidad hacia abajo (eje Y positivo = abajo).
	if not is_on_floor():
		velocity.y += gravity * delta


func _handle_jump() -> void:
	# Solo se puede saltar estando en el suelo (o sobre una plataforma). Saltar levanta.
	if _just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		is_crouching = false


func _handle_horizontal_movement(delta: float, can_turn: bool) -> void:
	# get_axis devuelve -1 (izquierda), 0 (nada) o 1 (derecha).
	var direction := _axis()
	var accel := acceleration if is_on_floor() else air_acceleration

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * move_speed, accel * delta)
		if can_turn:
			facing = signf(direction)
	elif is_on_floor():
		_brake(delta)


func _brake(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _update_hurtbox() -> void:
	# La zona golpeable se achica al agacharse (crece desde los pies).
	var low := is_crouching or (current_attack != null and current_attack.crouching)
	var size := crouch_hurtbox_size if low else stand_hurtbox_size
	if visual:
		size.y += visual.torso_lift   # personajes más altos: zona golpeable más alta
	var rect := hurtbox_shape.shape as RectangleShape2D
	if rect.size != size:
		rect.size = size
		hurtbox_shape.position = Vector2(0, -size.y / 2.0)


## Empuje suave entre luchadores (como la "pushbox" de los juegos de pelea).
## Cada uno se aparta la mitad de lo que se superpone con el otro; como los dos lo hacen,
## quien camina contra el rival lo va empujando, más lento. Se usa move_and_collide para
## no atravesar el escenario al apartarse.
func _push_away_from_fighters() -> void:
	for other in get_tree().get_nodes_in_group("fighters"):
		if other == self or not other is Node2D:
			continue
		var offset: Vector2 = global_position - (other as Node2D).global_position
		if absf(offset.y) >= push_height:
			continue
		var overlap := push_distance - absf(offset.x)
		if overlap <= 0.0:
			continue
		# Justo uno encima del otro: cada uno se aparta hacia su espalda.
		var away := signf(offset.x) if offset.x != 0.0 else -facing
		move_and_collide(Vector2(away * overlap * 0.5, 0.0))


# --- Ataques ---

func _handle_attack_input(on_floor: bool) -> void:
	var attack: AttackData = null
	if _just_pressed("punch"):
		if not on_floor:
			attack = air_punch_attack
		elif is_crouching:
			attack = crouch_punch_attack
		else:
			attack = punch_attack
	elif _just_pressed("kick"):
		if not on_floor:
			attack = air_kick_attack
		elif is_crouching:
			attack = crouch_kick_attack
		else:
			attack = kick_attack
	if attack:
		start_attack(attack)


func start_attack(attack: AttackData) -> void:
	current_attack = attack
	attack_frame = 0
	_already_hit.clear()

	# Colocar la hitbox según los datos del ataque, volteada si mira a la izquierda.
	var lift: float = visual.torso_lift if visual and attack.follows_torso else 0.0
	hitbox.position = Vector2(attack.hitbox_offset.x * facing, attack.hitbox_offset.y - lift)
	(hitbox_shape.shape as RectangleShape2D).size = attack.hitbox_size
	_set_hitbox_active(attack.is_active_frame(0))

	if visual:
		visual.set_facing(facing)
		visual.play_animation(attack.animation, true)


func _update_attack(on_floor: bool) -> void:
	# Un ataque aéreo termina al tocar el suelo.
	if current_attack.aerial and on_floor:
		_end_attack()
		return
	# Un cuadro de física = un cuadro de juego (60 por segundo).
	attack_frame += 1
	if attack_frame >= current_attack.total_frames:
		_end_attack()
	else:
		_set_hitbox_active(current_attack.is_active_frame(attack_frame))


func _end_attack() -> void:
	current_attack = null
	_set_hitbox_active(false)


func _set_hitbox_active(active: bool) -> void:
	# set_deferred: cambiar formas de física durante un callback de física
	# debe esperar al final del frame, si no Godot avisa con un error.
	hitbox_shape.set_deferred("disabled", not active)


func _on_hitbox_area_entered(area: Area2D) -> void:
	# Ignorar nuestra propia hurtbox y lo que ya golpeamos en este ataque.
	if current_attack == null or area == hurtbox or area in _already_hit:
		return
	_already_hit.append(area)
	var attack := current_attack
	# La hurtbox es hija del luchador golpeado: avisarle para que reaccione.
	var target := area.get_parent()
	if target and target.has_method("receive_hit"):
		target.receive_hit(attack, facing)
	# Quien golpea también retrocede un poco (bastante menos que el golpeado).
	velocity.x -= facing * attack.self_recoil
	hit_landed.emit(area, attack)


## Recibir un golpe. direction: hacia dónde empuja el golpe (1 = derecha, -1 = izquierda).
func receive_hit(attack: AttackData, direction: float) -> void:
	if current_attack:
		_end_attack()                      # un golpe interrumpe el ataque en curso
	is_crouching = false
	damage_taken += attack.damage
	hitstun_left = attack.hitstun_frames
	velocity = Vector2(attack.knockback.x * direction, attack.knockback.y)
	facing = -direction                    # mirar hacia quien golpeó
	if visual:
		visual.set_facing(facing)
		visual.play_animation(&"hurt", true)
		_flash()
	got_hit.emit(attack)


## Destello blanco breve al recibir un golpe.
func _flash() -> void:
	visual.modulate = Color(2.2, 2.2, 2.2)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.15)


# --- Entrada (teclado), o nada si es un muñeco ---

func _pressed(action: StringName) -> bool:
	return player_controlled and Input.is_action_pressed(action)


func _just_pressed(action: StringName) -> bool:
	return player_controlled and Input.is_action_just_pressed(action)


func _axis() -> float:
	return Input.get_axis("move_left", "move_right") if player_controlled else 0.0


# --- Animaciones ---

func _update_animation() -> void:
	# Durante un ataque, la animación la controla el propio ataque.
	if current_attack or visual == null:
		return

	visual.set_facing(facing)
	if not is_on_floor():
		visual.play_animation(&"jump" if velocity.y < 0.0 else &"fall")
	elif is_crouching:
		visual.play_animation(&"crouch")
	elif absf(velocity.x) > 10.0:
		visual.play_animation(&"walk")
	else:
		visual.play_animation(&"idle")
