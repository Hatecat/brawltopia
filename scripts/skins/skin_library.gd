class_name SkinLibrary
extends RefCounted
## Catálogo de skins disponibles: las del juego y las que agregan los jugadores.
##
## Una carpeta cuenta como skin si tiene al menos head.png. El nombre que se muestra
## es el "name" de su skin.json o, si no tiene, el nombre de la carpeta.

## Skins incluidas en el juego.
const GAME_SKINS_DIR := "res://assets/characters/skins"
## Skins de los jugadores (carpeta de datos del usuario; se crea si no existe).
const USER_SKINS_DIR := "user://skins"
## La skin "default" son las piezas provisorias: se lista al final como "Básico".
const DEFAULT_ID := "default"


## Lista de skins: [{"id", "name", "path", "source": "game" | "user"}], ordenadas por nombre.
static func list_skins() -> Array:
	var skins: Array = []
	for source in [["game", GAME_SKINS_DIR], ["user", USER_SKINS_DIR]]:
		var dir_path: String = source[1]
		if source[0] == "user":
			DirAccess.make_dir_recursive_absolute(dir_path)
		for folder in DirAccess.get_directories_at(dir_path):
			var path := dir_path.path_join(folder)
			if not _has_part(path, "head"):
				continue
			skins.append({
				"id": folder,
				"name": _display_name(path, folder),
				"path": path,
				"source": source[0],
			})
	skins.sort_custom(func(a, b):
		if (a["id"] == DEFAULT_ID) != (b["id"] == DEFAULT_ID):
			return b["id"] == DEFAULT_ID   # "Básico" al final
		return a["name"].naturalnocasecmp_to(b["name"]) < 0)
	return skins


## Ruta absoluta de la carpeta de skins de los jugadores (para mostrarla o abrirla).
static func user_skins_folder() -> String:
	DirAccess.make_dir_recursive_absolute(USER_SKINS_DIR)
	return ProjectSettings.globalize_path(USER_SKINS_DIR)


static func _has_part(dir: String, part: String) -> bool:
	var path := dir.path_join(part + ".png")
	if dir.begins_with("res://"):
		return ResourceLoader.exists(path)   # en el juego exportado las imágenes están importadas
	return FileAccess.file_exists(path)


static func _display_name(dir: String, folder: String) -> String:
	if folder == DEFAULT_ID:
		return "Básico"
	var meta_path := dir.path_join("skin.json")
	if FileAccess.file_exists(meta_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
		if data is Dictionary and str(data.get("name", "")).strip_edges() != "":
			return str(data["name"]).strip_edges().capitalize()
	return folder.capitalize()
