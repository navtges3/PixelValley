extends Window

const GREEN_BUTTON = preload("res://resources/themes/buttons/regular/green_button.tres")
const RED_BUTTON = preload("res://resources/themes/buttons/regular/red_button.tres")
const BACKGROUND = preload("res://resources/themes/backgrounds/background.tres")

@onready var overwrite_dialog: ConfirmationDialog = $OverwriteDialog
@onready var back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BackButton
@onready var slot_buttons: Array[Button] = [
	$PanelContainer/MarginContainer/VBoxContainer/SlotButton1,
	$PanelContainer/MarginContainer/VBoxContainer/SlotButton2,
	$PanelContainer/MarginContainer/VBoxContainer/SlotButton3,
	$PanelContainer/MarginContainer/VBoxContainer/SlotButton4,
	$PanelContainer/MarginContainer/VBoxContainer/SlotButton5,
]

var _pending_slot_index: int = 0

func _ready() -> void:
	exclusive = true
	_create_overwrite_dialog()
	populate_slots()

func _create_overwrite_dialog() -> void:
	overwrite_dialog.title = "Overwrite Save?"
	overwrite_dialog.dialog_text = "This slot already has save data. Start a new game here and overwrite it?"
	overwrite_dialog.theme = BACKGROUND
	overwrite_dialog.get_ok_button().theme = GREEN_BUTTON
	overwrite_dialog.get_cancel_button().theme = RED_BUTTON
	overwrite_dialog.confirmed.connect(_confirm_overwrite)

func populate_slots() -> void:
	for i in slot_buttons.size():
		var button := slot_buttons[i]
		var slot_index := i + 1
		if SaveManager.has_save_data(slot_index):
			var meta := SaveManager.get_meta_data(slot_index)
			setup_filled_slot(button, meta)
		else:
			setup_empty_slot(button)
		button.pressed.connect(_slot_button_pressed.bind(slot_index))

func setup_empty_slot(button: Button) -> void:
	button.text = "Empty Slot"
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.theme = RED_BUTTON

func setup_filled_slot(button: Button, meta: Dictionary) -> void:
	var hero_name: String = meta.get("hero_name", "Unknown")
	var level: int = meta.get("level", 1)
	var last_played: String = meta.get("time", "Unknown")

	button.text = "%s\nLevel: %d\nLast Played: %s" % [hero_name, level, last_played]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.theme = GREEN_BUTTON

func _slot_button_pressed(slot_index: int) -> void:
	if SaveManager.has_save_data(slot_index):
		_pending_slot_index = slot_index
		overwrite_dialog.popup_centered()
		return
	_start_new_game_in_slot(slot_index)

func _confirm_overwrite() -> void:
	if _pending_slot_index <= 0:
		return
	_start_new_game_in_slot(_pending_slot_index)
	_pending_slot_index = 0

func _start_new_game_in_slot(slot_index: int) -> void:
	self.hide()
	GameState.start_new_game(slot_index)
	ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE)

func _on_back_button_pressed() -> void:
	self.hide()
