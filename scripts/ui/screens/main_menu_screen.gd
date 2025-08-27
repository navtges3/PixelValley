extends Control

@onready var options_popup = $OptionsPopup
@onready var new_game_button = $"MarginContainer/VBoxContainer/New Game"
@onready var load_game_button = $"MarginContainer/VBoxContainer/Load Game"
@onready var options_button = $MarginContainer/VBoxContainer/Options
@onready var exit_button = $"MarginContainer/VBoxContainer/Exit Game"

func _ready() -> void:
	options_popup.hide()
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	if SaveManager.has_save_data():
		load_game_button.disabled = false
		load_game_button.pressed.connect(_on_load_game_button_pressed)
	else:
		load_game_button.disabled = true
	options_button.pressed.connect(_on_options_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)

func _on_new_game_button_pressed():
	ScreenManager.go_to_screen("new_game")

func _on_load_game_button_pressed():
	SaveManager.load_game()
	if GameState.hero and GameState.village:
		ScreenManager.go_to_screen("village")

func _on_options_button_pressed():
	options_popup.popup_centered()

func _on_exit_button_pressed():
	get_tree().quit()
