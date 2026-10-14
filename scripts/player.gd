extends CharacterBody2D
## Jugador controlable: movimiento horizontal, salto y gravedad.
##
## CharacterBody2D no se mueve solo: cada frame de física calculamos
## `velocity` y llamamos a move_and_slide(), que mueve el cuerpo,
## lo detiene al chocar y actualiza is_on_floor().

# --- Parámetros ajustables desde el Inspector (@export) ---
@export var move_speed: float = 420.0      ## Velocidad horizontal máxima (px/s).
@export var acceleration: float = 3200.0   ## Qué tan rápido alcanza move_speed.
@export var friction: float = 2800.0       ## Qué tan rápido frena al soltar.
@export var jump_velocity: float = -900.0  ## Impulso del salto (negativo = hacia arriba).

# La gravedad se lee de Project Settings > Physics > 2D > Default Gravity,
# así todos los objetos del juego comparten el mismo valor.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_horizontal_movement(delta)
	move_and_slide()


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
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
