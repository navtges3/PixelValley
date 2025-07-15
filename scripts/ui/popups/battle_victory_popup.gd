extends Window

signal continue_pressed
signal retreat_pressed

@onready var retreat_button = $VBoxContainer/HBoxContainer/RetreatButton
@onready var continue_button = $VBoxContainer/HBoxContainer/ContinueButton

func _ready() -> void:
	exclusive = true
	continue_button.grab_focus()
	continue_button.pressed.connect(_on_continue_button_pressed)
	retreat_button.pressed.connect(_on_retreat_button_pressed)

func _on_continue_button_pressed() -> void:
	hide()
	emit_signal("continue_pressed")

func _on_retreat_button_pressed() -> void:
	hide()
	emit_signal("retreat_pressed")
