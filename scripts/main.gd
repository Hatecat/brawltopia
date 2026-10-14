extends Node2D
## Escena de pelea: une el escenario, los luchadores y la cámara.
##
## - Viste al jugador con la skin elegida en la pantalla de selección (GameState).
## - El muñeco de práctica (Dummy) no se controla: sirve para probar los golpes.
## - Si un luchador cae fuera del escenario, vuelve a su punto de aparición.
## - Esc vuelve a la pantalla de selección de personaje.

## Si un luchador baja de esta altura (px), reaparece.
@export var fall_limit_y: float = 1000.0

@onready var player: CharacterBody2D = $Player
@onready var dummy: CharacterBody2D = $Dummy
@onready var spawn_points := {player: $SpawnPoint, dummy: $DummySpawnPoint}


func _ready() -> void:
	if GameState.selected_skin_path != "" and player.visual and player.visual.has_method("load_skin"):
		player.visual.load_skin(GameState.selected_skin_path)
	for fighter in spawn_points:
		_respawn(fighter)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameState.go_to_character_select()


func _physics_process(_delta: float) -> void:
	for fighter in spawn_points:
		if fighter.global_position.y > fall_limit_y:
			_respawn(fighter)


func _respawn(fighter: CharacterBody2D) -> void:
	fighter.global_position = (spawn_points[fighter] as Marker2D).global_position
	fighter.velocity = Vector2.ZERO
	fighter.hitstun_left = 0
	fighter.damage_taken = 0.0
