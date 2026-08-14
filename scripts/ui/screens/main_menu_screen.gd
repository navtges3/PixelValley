extends Control
class_name MainMenuScreen

@onready var options_window: OptionsWindow = $OptionsWindow
@onready var load_window: LoadWindow = $LoadWindow

@onready var new_game_button: Button = $MarginContainer/VBoxContainer/NewGameButton
@onready var load_game_button: Button = $MarginContainer/VBoxContainer/LoadGameButton

func _ready() -> void:
	GameState.reset_state()
	AudioManager.play_music_by_id("background")
	InputManager.push_menu_focus_context(
		self,
		Callable(self, "_get_default_focus_target")
	)

func _get_default_focus_target() -> Control:
	return new_game_button

func _exit_tree() -> void:
	InputManager.pop_menu_focus_context(self)

func _on_new_game_button_pressed() -> void:
	ScreenManager.go_to_screen(ScreenManager.ScreenName.NEW_GAME)

func _on_load_game_button_pressed() -> void:
	load_window.open()

func _on_options_button_pressed() -> void:
	options_window.open()

func _on_exit_button_pressed() -> void:
	get_tree().quit()
