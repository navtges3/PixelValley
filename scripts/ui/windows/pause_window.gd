extends Window

@onready var options_window: Window = $OptionsWindow

func _on_resume_button_pressed() -> void:
	hide()

func _on_options_button_pressed() -> void:
	options_window.popup_centered()

func _on_save_exit_button_pressed() -> void:
	SaveManager.save_game()
	ScreenManager.go_to_screen(ScreenManager.ScreenName.MAIN_MENU)
