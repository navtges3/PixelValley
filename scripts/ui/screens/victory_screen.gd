extends Control

func _on_main_menu_button_pressed() -> void:
	ScreenManager.go_to_screen(ScreenManager.ScreenName.MAIN_MENU)
