extends Control

@onready var options_popup = $OptionsPopup
@onready var load_window: Window = $LoadWindow

@onready var load_game_button: Button = $MarginContainer/VBoxContainer/LoadGameButton

func _ready() -> void:
	options_popup.hide()
	GameState.reset_state()
	if SaveManager.has_save_data():
		load_game_button.disabled = false
	else:
		load_game_button.disabled = true
	AudioManager.play_music_by_id("background")

func _on_new_game_button_pressed():
	ScreenManager.go_to_screen(ScreenManager.ScreenName.NEW_GAME)

func _on_load_game_button_pressed():
	load_window.popup_centered()

func _on_options_button_pressed():
	options_popup.popup_centered()

func _on_exit_button_pressed():
	get_tree().quit()
