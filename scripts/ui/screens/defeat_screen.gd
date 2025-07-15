extends Control

@onready var reason_label = $VBoxContainer/ReasonLabel
@onready var main_menu_button = $VBoxContainer/MainMenuButton

func _ready() -> void:
	var reason_text = "You have been defeated.\n"
	if GameState.village.is_destroyed():
		reason_text += "Your village has been destroyed."
	elif not GameState.hero.is_alive():
		reason_text += "Your hero has fallen in battle."
	reason_label.text = reason_text
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)

func _on_main_menu_button_pressed() -> void:
	ScreenManager.go_to_screen("main_menu")