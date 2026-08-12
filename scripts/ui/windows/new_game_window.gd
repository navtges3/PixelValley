extends GameWindow
class_name NewGameWindow

@onready var overwrite_window: ConfirmationWindow = $OverwriteWindow
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
	super._ready()
	_create_overwrite_window()
	populate_slots()
	_configure_focus_graph()

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
	button.theme = ThemeManager.RED_BUTTON

func setup_filled_slot(button: Button, meta: Dictionary) -> void:
	var hero_name: String = meta.get("hero_name", "Unknown")
	var level: int = meta.get("level", 1)
	var last_played: String = meta.get("time", "Unknown")

	button.text = "%s\nLevel: %d\nLast Played: %s" % [hero_name, level, last_played]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.theme = ThemeManager.GREEN_BUTTON

func _cancel_overwrite() -> void:
	_pending_slot_index = 0

func _confirm_overwrite() -> void:
	if _pending_slot_index <= 0:
		return
	_start_new_game_in_slot(_pending_slot_index)
	_pending_slot_index = 0

func _create_overwrite_window() -> void:
	overwrite_window.setup(
		"Overwrite Save?",
		"This slot already has save data. Start a new game here and overwrite it?",
		"Overwrite"
	)
	overwrite_window.confirmed.connect(_confirm_overwrite)
	overwrite_window.cancelled.connect(_cancel_overwrite)

func _get_default_focus_target() -> Control:
	if slot_buttons.is_empty():
		return back_button
	return slot_buttons[0]

func _configure_focus_graph() -> void:
	if slot_buttons.is_empty():
		back_button.focus_neighbor_top = back_button.get_path_to(back_button)
		return

	for index: int in slot_buttons.size():
		var button: Button = slot_buttons[index]
		var top_target: Control = button
		var bottom_target: Control = back_button
		if index > 0:
			top_target = slot_buttons[index - 1]
		if index < slot_buttons.size() - 1:
			bottom_target = slot_buttons[index + 1]
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(button)
		button.focus_neighbor_top = button.get_path_to(top_target)
		button.focus_neighbor_bottom = button.get_path_to(bottom_target)

	back_button.focus_neighbor_left = back_button.get_path_to(back_button)
	back_button.focus_neighbor_right = back_button.get_path_to(back_button)
	back_button.focus_neighbor_top = back_button.get_path_to(slot_buttons.back())

func _slot_button_pressed(slot_index: int) -> void:
	if SaveManager.has_save_data(slot_index):
		_pending_slot_index = slot_index
		overwrite_window.open()
		return
	_start_new_game_in_slot(slot_index)

func _start_new_game_in_slot(slot_index: int) -> void:
	close()
	GameState.start_new_game(slot_index)
	ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE)

func _on_back_button_pressed() -> void:
	close()
