extends Window

@onready var resume_button = $VBoxContainer/ResumeButton
@onready var options_button = $VBoxContainer/OptionsButton
@onready var save_exit_button = $VBoxContainer/SaveExitButton

@onready var options_popup = $OptionsPopup

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	save_exit_button.pressed.connect(_on_exit_pressed)

func _on_resume_pressed():
	hide()

func _on_options_pressed():
	options_popup.popup_centered()

func _on_exit_pressed():
	GameState.save_game()
	ScreenManager.go_to_screen(ScreenManager.ScreenName.MAIN_MENU)
