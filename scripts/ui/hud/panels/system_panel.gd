extends Control
class_name SystemPanel

@onready var options_window: Window = $OptionsWindow
@onready var save_button: Button = $VBoxContainer/SaveButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton
@onready var status_label: Label = $VBoxContainer/StatusLabel

const COLOR_STATUS_OK  := Color(0.25, 0.85, 0.35)
const COLOR_STATUS_ERR := Color(0.85, 0.22, 0.18)

func _ready() -> void:
	status_label.text = ""

func refresh() -> void:
	status_label.text = ""

func _on_save_button_pressed() -> void:
	SaveManager.save_game()
	_show_status("Game saved!", COLOR_STATUS_OK)

func _on_options_button_pressed() -> void:
	options_window.popup_centered()

func _on_main_menu_button_pressed() -> void:
	SaveManager.save_game()
	ScreenManager.go_to_screen(ScreenManager.ScreenName.MAIN_MENU)

func _show_status(msg: String, color: Color) -> void:
	status_label.text = msg
	status_label.add_theme_color_override("font_color", color)
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(status_label):
		status_label.text = ""
