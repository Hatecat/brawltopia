extends Node
## Estado global del juego (autoload "GameState"): sobrevive al cambiar de escena.
##
## Por ahora guarda qué personaje eligió el jugador. Más adelante: modo de juego,
## escenario, cantidad de jugadores, etc.

## Escena de la pantalla de selección y de la pelea.
const CHARACTER_SELECT_SCENE := "res://scenes/ui/character_select.tscn"
const FIGHT_SCENE := "res://scenes/main.tscn"

## Carpeta de la skin elegida. Vacío = la que traiga el jugador por defecto.
var selected_skin_path: String = ""
## Nombre para mostrar de la skin elegida.
var selected_skin_name: String = ""


func choose_skin(path: String, display_name: String) -> void:
	selected_skin_path = path
	selected_skin_name = display_name


func go_to_fight() -> void:
	get_tree().change_scene_to_file(FIGHT_SCENE)


func go_to_character_select() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)
