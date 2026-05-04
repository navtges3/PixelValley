extends Window
class_name DeathWindow

signal return_to_village

@onready var return_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ReturnButton

func _ready() -> void:
	close_requested.connect(_on_close_requested)

func _on_return_button_pressed() -> void:
	return_to_village.emit()

func _on_close_requested() -> void:
	pass
