extends Node2D
## Escena principal: une el escenario y el jugador.
##
## Por ahora solo hace una cosa: si el jugador cae fuera del escenario,
## lo devuelve al punto de aparición. Así puedes probar sin reiniciar.

## Si el jugador baja de esta altura (px), reaparece.
@export var fall_limit_y: float = 1000.0

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint


func _ready() -> void:
	_respawn_player()


func _physics_process(_delta: float) -> void:
	if player.global_position.y > fall_limit_y:
		_respawn_player()


func _respawn_player() -> void:
	player.global_position = spawn_point.global_position
	player.velocity = Vector2.ZERO
