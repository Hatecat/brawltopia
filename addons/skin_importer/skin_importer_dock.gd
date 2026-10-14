@tool
extends VBoxContainer
## Panel "Skins": elige una hoja de piezas, ponle nombre y pulsa Importar.
## Las piezas quedan en res://assets/characters/skins/<nombre>/ listas para usar.

const SKINS_DIR := "res://assets/characters/skins"

var _sheet_path := ""
var _path_label: Label
var _name_edit: LineEdit
var _side_check: CheckBox
var _import_button: Button
var _status: Label
var _preview: HFlowContainer
var _dialog: ConfirmationDialog  # EditorFileDialog en el editor, FileDialog fuera de él


func _init() -> void:
	name = "Skins"
	add_theme_constant_override("separation", 8)

	var intro := Label.new()
	intro.text = "Convierte una hoja con 4 piezas sobre fondo magenta (cabeza y cuerpo arriba; brazo y pierna abajo) en una skin."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(intro)

	var pick := Button.new()
	pick.text = "Elegir hoja…"
	pick.pressed.connect(_on_pick_pressed)
	add_child(pick)

	_path_label = Label.new()
	_path_label.text = "Ninguna hoja elegida."
	_path_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_path_label.modulate = Color(1, 1, 1, 0.7)
	add_child(_path_label)

	var name_label := Label.new()
	name_label.text = "Nombre de la skin:"
	add_child(name_label)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "por ejemplo: gerald"
	_name_edit.text_changed.connect(func(_t): _refresh_button())
	add_child(_name_edit)

	_side_check = CheckBox.new()
	_side_check.text = "Hoja B: lado derecho (piezas mirando a la izquierda)"
	_side_check.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_side_check)

	_import_button = Button.new()
	_import_button.text = "Importar"
	_import_button.disabled = true
	_import_button.pressed.connect(_on_import_pressed)
	add_child(_import_button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)

	_preview = HFlowContainer.new()
	add_child(_preview)

	_dialog = EditorFileDialog.new() if Engine.is_editor_hint() else FileDialog.new()
	_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialog.access = FileDialog.ACCESS_FILESYSTEM   # se puede elegir desde cualquier carpeta
	_dialog.title = "Elegir hoja de piezas"
	_dialog.add_filter("*.png, *.jpg, *.jpeg, *.webp", "Imágenes")
	_dialog.file_selected.connect(_on_file_selected)
	add_child(_dialog)


func _on_pick_pressed() -> void:
	_dialog.popup_centered_ratio(0.6)


func _on_file_selected(path: String) -> void:
	_sheet_path = path
	_path_label.text = path
	if _name_edit.text.strip_edges() == "":
		# Sugerir un nombre a partir del archivo: "Gerald-A.png" → "gerald"
		var suggestion := path.get_file().get_basename().to_lower()
		suggestion = suggestion.replace("designer-", "").get_slice("-", 0)
		_name_edit.text = _clean_name(suggestion)
	_refresh_button()


func _refresh_button() -> void:
	_import_button.disabled = _sheet_path == "" or _clean_name(_name_edit.text) == ""


func _on_import_pressed() -> void:
	var skin_name := _clean_name(_name_edit.text)
	_name_edit.text = skin_name
	var image := Image.load_from_file(_sheet_path)
	if image == null or image.is_empty():
		_show("No se pudo abrir la imagen.", false)
		return
	_show("Procesando…", true)
	await get_tree().process_frame  # que el mensaje alcance a verse

	var skin_dir := SKINS_DIR.path_join(skin_name)
	var result := SheetImporter.import_sheet(image, skin_dir, _side_check.button_pressed)
	if not result["ok"]:
		_show(result["message"], false)
		return

	var lines := PackedStringArray()
	for part in result["parts"]:
		var info: Dictionary = result["parts"][part]
		lines.append("  %s: %dx%d px, unión %s" % [part, info["size"].x, info["size"].y, info["pivot"]])
	_show("Listo: %s\n%s\n\nPara usarla: en main.tscn, nodo Player → Skin Path = %s" % [skin_dir, "\n".join(lines), skin_dir], true)
	_show_preview(skin_dir, result["parts"].keys())
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()  # que Godot importe las imágenes nuevas


func _show_preview(skin_dir: String, parts: Array) -> void:
	for child in _preview.get_children():
		child.queue_free()
	for part in parts:
		var img := Image.load_from_file(skin_dir.path_join(part + ".png"))
		if img == null:
			continue
		var tex_rect := TextureRect.new()
		tex_rect.texture = ImageTexture.create_from_image(img)
		tex_rect.custom_minimum_size = Vector2(56, 96)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.tooltip_text = part
		_preview.add_child(tex_rect)


func _show(message: String, ok: bool) -> void:
	_status.text = message
	_status.modulate = Color.WHITE if ok else Color(1.0, 0.55, 0.5)


## Nombre de carpeta seguro: minúsculas, números, "_" y "-".
static func _clean_name(text: String) -> String:
	var out := ""
	for ch in text.strip_edges().to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == "_" or ch == "-":
			out += ch
		elif ch == " ":
			out += "_"
	return out
