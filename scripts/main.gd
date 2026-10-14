extends Node2D
## Escena de pelea: une el escenario, el jugador y la cámara.
##
## - Viste al jugador con la skin elegida en la pantalla de selección (GameState).
## - Si el jugador cae fuera del escenario, lo devuelve al punto de aparición.
## - Esc vuelve a la pantalla de selección de personaje.

## Si el jugador baja de esta altura (px), reaparece.
@export var fall_limit_y: float = 1000.0

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint


func _ready() -> void:
	if GameState.selected_skin_path != "" and player.visual and player.visual.has_method("load_skin"):
		player.visual.load_skin(GameState.selected_skin_path)
	_respawn_player()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameState.go_to_character_select()


func _physics_process(_delta: float) -> void:
	if player.global_position.y > fall_limit_y:
		_respawn_player()


func _respawn_player() -> void:
	player.global_position = spawn_point.global_position
	player.velocity = Vector2.ZERO
