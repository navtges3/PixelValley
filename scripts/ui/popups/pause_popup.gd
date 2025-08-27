extends Window

@onready var resume_button = $VBoxContainer/ResumeButton
@onready var options_button = $VBoxContainer/OptionsButton
@onready var save_exit_button = $VBoxContainer/SaveExitButton

@onready var options_popup = $OptionsPopup

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visibility_changed.connect(_on_pause_popup_visibility_changed)
	about_to_popup.connect(_on_pause_popup_about_to_popup)
	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	save_exit_button.pressed.connect(_on_exit_pressed)

func _on_resume_pressed():
	hide()

func _on_options_pressed():
	options_popup.popup_centered()

func _on_exit_pressed():
	SaveManager.save_game()
	get_tree().paused = false
	ScreenManager.go_to_screen("main_menu")

func _on_pause_popup_about_to_popup():
	get_tree().paused = true

func _on_pause_popup_visibility_changed():
	if not is_visible():
		get_tree().paused = false
