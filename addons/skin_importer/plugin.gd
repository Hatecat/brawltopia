@tool
extends EditorPlugin
## Agrega el panel "Skins" al editor de Godot (a la derecha, junto al Inspector).

var _dock: Control


func _enter_tree() -> void:
	_dock = preload("res://addons/skin_importer/skin_importer_dock.gd").new()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
