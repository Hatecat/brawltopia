extends Control
## Pantalla "Elige tu personaje".
##
## Lee las skins disponibles (SkinLibrary): las del juego y las de la carpeta del jugador.
## Muestra una tarjeta por skin con el personaje animado y, a la izquierda, una vista
## grande del que está seleccionado. Se maneja con teclado (flechas + Enter o J) o mouse.

const RIG_VISUAL := preload("res://scenes/characters/visuals/rig_visual.tscn")

const BG := Color("15161d")
const CARD := Color("23252f")
const CARD_BORDER := Color("2f3240")
const CARD_HOVER := Color("4a4f66")
const ACCENT := Color("f2a33a")
const TEXT_MUTED := Color(1, 1, 1, 0.55)

const CARD_SIZE := Vector2(230, 290)
const CARD_PREVIEW_SCALE := 2.6
const BIG_PREVIEW_SCALE := 7.0

var _skins: Array = []
var _cards: Array[Button] = []
var _card_visuals: Array = []
var _big_preview
var _name_label: Label
var _source_label: Label
var _confirming := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_skins = SkinLibrary.list_skins()
	_build()
	if _cards.is_empty():
		return
	# Enfocar la skin elegida antes (si se vuelve desde la pelea) o la primera.
	var start := 0
	for i in _skins.size():
		if _skins[i]["path"] == GameState.selected_skin_path:
			start = i
	_cards[start].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _confirming:
		return
	if event.is_action_pressed("punch"):
		# J también confirma (además de Enter / Espacio).
		var focused := get_viewport().gui_get_focus_owner()
		if focused in _cards:
			_confirm(_cards.find(focused))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# --- Vista grande (izquierda) ---
	var floor_line := ColorRect.new()
	floor_line.color = CARD_BORDER
	floor_line.position = Vector2(80, 860)
	floor_line.size = Vector2(600, 4)
	add_child(floor_line)

	_name_label = _label("", 56, Vector2(80, 880), Vector2(600, 70))
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_source_label = _label("", 22, Vector2(80, 950), Vector2(600, 32), TEXT_MUTED)
	_source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# --- Lista de personajes (derecha) ---
	_label("Elige tu personaje", 52, Vector2(800, 70), Vector2(1000, 70))

	if _skins.is_empty():
		_label("No hay skins. Agrega una carpeta con head.png, body.png, arm.png y leg.png en:\n" +
			SkinLibrary.user_skins_folder(), 26, Vector2(800, 180), Vector2(1040, 200), TEXT_MUTED)
		return

	var grid := GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(800, 170)
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	add_child(grid)

	for i in _skins.size():
		var card := _make_card(_skins[i])
		grid.add_child(card)
		card.focus_entered.connect(_on_card_focused.bind(i))
		card.mouse_entered.connect(card.grab_focus)
		card.pressed.connect(_confirm.bind(i))
		_cards.append(card)

	_big_preview = RIG_VISUAL.instantiate()
	_big_preview.position = Vector2(380, 858)
	_big_preview.scale = Vector2.ONE * BIG_PREVIEW_SCALE
	_big_preview.skin_path = _skins[0]["path"]
	add_child(_big_preview)

	# --- Ayuda (abajo) ---
	_label("Flechas: elegir     Enter o J: confirmar     Esc: salir", 24, Vector2(800, 940), Vector2(1040, 36), TEXT_MUTED)
	var folder_button := Button.new()
	folder_button.text = "Abrir la carpeta de skins de jugadores"
	folder_button.focus_mode = Control.FOCUS_NONE
	folder_button.position = Vector2(800, 990)
	folder_button.add_theme_font_size_override("font_size", 20)
	folder_button.pressed.connect(func(): OS.shell_open(SkinLibrary.user_skins_folder()))
	add_child(folder_button)


func _make_card(skin: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_stylebox_override("normal", _card_style(CARD, CARD_BORDER, 2))
	card.add_theme_stylebox_override("hover", _card_style(CARD, CARD_HOVER, 2))
	card.add_theme_stylebox_override("pressed", _card_style(Color("2b2e3a"), ACCENT, 4))
	card.add_theme_stylebox_override("focus", _card_style(Color(0, 0, 0, 0), ACCENT, 4))

	var visual = RIG_VISUAL.instantiate()
	visual.skin_path = skin["path"]
	visual.position = Vector2(CARD_SIZE.x / 2.0, 236)
	visual.scale = Vector2.ONE * CARD_PREVIEW_SCALE
	card.add_child(visual)
	_card_visuals.append(visual)

	var name_label := Label.new()
	name_label.text = skin["name"]
	name_label.position = Vector2(0, 244)
	name_label.size = Vector2(CARD_SIZE.x, 36)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)
	return card


func _on_card_focused(index: int) -> void:
	if _confirming:
		return
	var skin: Dictionary = _skins[index]
	_name_label.text = skin["name"]
	_source_label.text = "Skin del juego" if skin["source"] == "game" else "Tu skin"
	_big_preview.load_skin(skin["path"])
	_big_preview.play_animation(&"idle", true)
	# La tarjeta elegida camina; las demás quedan quietas.
	for i in _card_visuals.size():
		_card_visuals[i].play_animation(&"walk" if i == index else &"idle")


func _confirm(index: int) -> void:
	if _confirming:
		return
	_confirming = true
	var skin: Dictionary = _skins[index]
	GameState.choose_skin(skin["path"], skin["name"])
	_big_preview.play_animation(&"punch", true)
	await get_tree().create_timer(0.45).timeout
	GameState.go_to_fight()


func _label(text: String, font_size: int, pos: Vector2, size: Vector2, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label


static func _card_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(16)
	return style
