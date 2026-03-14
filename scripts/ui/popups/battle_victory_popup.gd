extends Window

signal continue_pressed
signal retreat_pressed

func _ready() -> void:
	exclusive = true

func _on_continue_button_pressed() -> void:
	hide()
	emit_signal("continue_pressed")

func _on_retreat_button_pressed() -> void:
	hide()
	emit_signal("retreat_pressed")
