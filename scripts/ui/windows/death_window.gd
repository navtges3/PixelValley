extends GameWindow
class_name DeathWindow

signal return_to_village

@onready var return_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ReturnButton

func _ready() -> void:
	super._ready()

func _get_default_focus_target() -> Control:
	return return_button

func _handle_cancel() -> void:
	_on_return_button_pressed()

func _on_return_button_pressed() -> void:
	return_to_village.emit()
