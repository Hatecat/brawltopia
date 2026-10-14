extends CharacterBody2D
## Jugador controlable: movimiento, salto, gravedad, animaciones y ataques.
##
## CharacterBody2D no se mueve solo: cada frame de física calculamos
## `velocity` y llamamos a move_and_slide(), que mueve el cuerpo,
## lo detiene al chocar y actualiza is_on_floor().

## Se emite cuando un ataque toca la hurtbox de otro personaje.
signal hit_landed(target: Area2D, attack: AttackData)

# --- Parámetros ajustables desde el Inspector (@export) ---
@export var move_speed: float = 420.0      ## Velocidad horizontal máxima (px/s).
@export var acceleration: float = 3200.0   ## Qué tan rápido alcanza move_speed.
@export var friction: float = 2800.0       ## Qué tan rápido frena al soltar.
@export var jump_velocity: float = -900.0  ## Impulso del salto (negativo = hacia arriba).

@export_group("Ataques")
@export var punch_attack: AttackData  ## Se lanza con la acción "punch".
@export var kick_attack: AttackData   ## Se lanza con la acción "kick".

# La gravedad se lee de Project Settings > Physics > 2D > Default Gravity,
# así todos los objetos del juego comparten el mismo valor.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

## Hacia dónde mira: 1 = derecha, -1 = izquierda.
var facing: float = 1.0

## Ataque en curso, o null si no está atacando.
var current_attack: AttackData = null

# Hurtboxes ya golpeadas en este ataque (para no golpear dos veces lo mismo).
var _already_hit: Array[Area2D] = []

# Nodos de la escena. @onready los busca cuando la escena ya está lista.
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D


func _ready() -> void:
	# Conectamos señales: Godot llamará a estas funciones cuando ocurra cada evento.
	sprite.frame_changed.connect(_on_sprite_frame_changed)
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	hitbox.area_entered.connect(_on_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	if current_attack == null:
		_handle_attack_input()

	if current_attack == null:
		_handle_jump()
		_handle_horizontal_movement(delta)
	else:
		# Mientras ataca no puede moverse: solo frena.
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()
	_update_animation()


func _apply_gravity(delta: float) -> void:
	# En el aire acumulamos velocidad hacia abajo (eje Y positivo = abajo).
	if not is_on_floor():
		velocity.y += gravity * delta


func _handle_jump() -> void:
	# Solo se puede saltar estando en el suelo (o sobre una plataforma).
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity


func _handle_horizontal_movement(delta: float) -> void:
	# get_axis devuelve -1 (izquierda), 0 (nada) o 1 (derecha).
	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
		facing = signf(direction)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


# --- Ataques ---

func _handle_attack_input() -> void:
	# Por ahora los ataques son solo en el suelo (los aéreos vendrán después).
	if not is_on_floor():
		return
	if Input.is_action_just_pressed("punch") and punch_attack:
		start_attack(punch_attack)
	elif Input.is_action_just_pressed("kick") and kick_attack:
		start_attack(kick_attack)


func start_attack(attack: AttackData) -> void:
	current_attack = attack
	_already_hit.clear()

	# Colocar la hitbox según los datos del ataque, volteada si mira a la izquierda.
	hitbox.position = Vector2(attack.hitbox_offset.x * facing, attack.hitbox_offset.y)
	(hitbox_shape.shape as RectangleShape2D).size = attack.hitbox_size

	sprite.flip_h = facing < 0.0
	sprite.play(attack.animation)
	sprite.frame = 0  # empezar siempre desde el inicio, aunque se repita el mismo ataque
	_set_hitbox_active(attack.is_active_frame(0))


func _end_attack() -> void:
	current_attack = null
	_set_hitbox_active(false)


func _set_hitbox_active(active: bool) -> void:
	# set_deferred: cambiar formas de física durante un callback de física
	# debe esperar al final del frame, si no Godot avisa con un error.
	hitbox_shape.set_deferred("disabled", not active)


func _on_sprite_frame_changed() -> void:
	if current_attack:
		_set_hitbox_active(current_attack.is_active_frame(sprite.frame))


func _on_sprite_animation_finished() -> void:
	if current_attack and sprite.animation == current_attack.animation:
		_end_attack()


func _on_hitbox_area_entered(area: Area2D) -> void:
	# Ignorar nuestra propia hurtbox y lo que ya golpeamos en este ataque.
	if current_attack == null or area == hurtbox or area in _already_hit:
		return
	_already_hit.append(area)
	hit_landed.emit(area, current_attack)


# --- Animaciones ---

func _update_animation() -> void:
	# Durante un ataque, la animación la controla el propio ataque.
	if current_attack:
		return

	# Los dibujos miran a la derecha; hacia la izquierda los volteamos.
	sprite.flip_h = facing < 0.0

	# play() no reinicia la animación si ya se está reproduciendo.
	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 10.0:
		sprite.play("walk")
	else:
		sprite.play("idle")
