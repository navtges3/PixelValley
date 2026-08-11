
extends GameWindow
class_name LoadWindow

const GREEN_BUTTON = preload("uid://cgbnpl6hlm7s2")
const RED_BUTTON = preload("uid://130ubmqd1h3b")

@onready var delete_confirmation: ConfirmationWindow = $DeleteConfirmation

@onready var slot_buttons: Array[Button] = [
	$PanelContainer/MarginContainer/VBoxContainer/GridContainer/SlotButton1,
	$PanelContainer/MarginContainer/VBoxContainer/GridContainer/SlotButton2,
	$PanelContainer/MarginContainer/VBoxContainer/GridContainer/SlotButton3,
	$PanelContainer/MarginContainer/VBoxContainer/GridContainer/SlotButton4,
	$PanelContainer/MarginContainer/VBoxContainer/GridContainer/SlotButton5
]
@onready var delete_buttons: Array[Button] = [
	$PanelContainer/MarginContainer/VBoxContainer/GridContainer/DeleteButton1,
	$PanelContainer/MarginContainer/VBoxContainer/GridContainer/DeleteButton2,
	$PanelContainer/MarginContainer/VBoxContainer/GridContainer/DeleteButton3,
	$PanelContainer/MarginContainer/VBoxContainer/GridContainer/DeleteButton4,
	$PanelContainer/MarginContainer/VBoxContainer/GridContainer/DeleteButton5
]

@onready var back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BackButton

var _pending_delete_slot: int = 0

func _ready() -> void:
	super._ready()
	delete_confirmation.confirmed.connect(_confirm_delete)
	delete_confirmation.cancelled.connect(_cancel_delete)
	for i: int in slot_buttons.size():
		var slot_index := i + 1
		slot_buttons[i].pressed.connect(_on_slot_button_pressed.bind(slot_index))
		delete_buttons[i].pressed.connect(_on_delete_button_pressed.bind(slot_index))
	populate_slots()
	_rebuild_focus_graph()

func populate_slots() -> void:
	for i in slot_buttons.size():
		var slot_index := i + 1
		if SaveManager.has_save_data(slot_index):
			var meta := SaveManager.get_meta_data(slot_index)
			setup_filled_slot(slot_buttons[i], meta)
			delete_buttons[i].disabled = false
		else:
			setup_empty_slot(slot_buttons[i])
			delete_buttons[i].disabled = true

func setup_empty_slot(button: Button) -> void:
	button.text = "Empty Slot"
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.theme = RED_BUTTON
	button.disabled = true

func setup_filled_slot(button: Button, meta: Dictionary) -> void:
	var hero_name: String = meta.get("hero_name", "Unknown")
	var level: int = meta.get("level", 1)
	var last_played: String = meta.get("time", "Unknown")
	button.text = "%s\nLevel: %d\nLast Played: %s" % [hero_name, level, last_played]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.theme = GREEN_BUTTON
	button.disabled = false

func _cancel_delete() -> void:
	_pending_delete_slot = 0

func _confirm_delete() -> void:
	if _pending_delete_slot <= 0:
		return
	SaveManager.delete_slot(_pending_delete_slot)
	_pending_delete_slot = 0
	populate_slots()
	_rebuild_focus_graph()
	_apply_default_focus.call_deferred()

func _get_default_focus_target() -> Control:
	for button: Button in slot_buttons:
		if not button.disabled:
			return button
	return back_button

func _rebuild_focus_graph() -> void:
	var enabled_rows: Array[int] = []
	for index: int in slot_buttons.size():
		if not slot_buttons[index].disabled:
			enabled_rows.append(index)

	if enabled_rows.is_empty():
		back_button.focus_neighbor_top = back_button.get_path_to(back_button)
		return

	for enabled_index: int in enabled_rows.size():
		var row: int = enabled_rows[enabled_index]
		var slot_button: Button = slot_buttons[row]
		var delete_button: Button = delete_buttons[row]
		var top_target: Control = slot_button
		var bottom_target: Control = back_button

		if enabled_index > 0:
			top_target = slot_buttons[enabled_rows[enabled_index - 1]]
		if enabled_index < enabled_rows.size() - 1:
			bottom_target = slot_buttons[enabled_rows[enabled_index + 1]]

		slot_button.focus_neighbor_left = slot_button.get_path_to(slot_button)
		slot_button.focus_neighbor_right = slot_button.get_path_to(delete_button)
		slot_button.focus_neighbor_top = slot_button.get_path_to(top_target)
		slot_button.focus_neighbor_bottom = slot_button.get_path_to(bottom_target)

		delete_button.focus_neighbor_left = delete_button.get_path_to(slot_button)
		delete_button.focus_neighbor_right = delete_button.get_path_to(delete_button)
		delete_button.focus_neighbor_top = delete_button.get_path_to(
			delete_buttons[enabled_rows[enabled_index - 1]]
			if enabled_index > 0 else delete_button
		)
		delete_button.focus_neighbor_bottom = delete_button.get_path_to(
			delete_buttons[enabled_rows[enabled_index + 1]]
			if enabled_index < enabled_rows.size() - 1 else back_button
		)

	back_button.focus_neighbor_top = back_button.get_path_to(
		slot_buttons[enabled_rows.back()]
	)

func _on_back_button_pressed() -> void:
	close()

func _on_delete_button_pressed(slot: int) -> void:
	_pending_delete_slot = slot
	delete_confirmation.setup("Delete Save?",
		"Delete the save in slot %d? This cannot be undone." % slot,
		"Delete")
	delete_confirmation.open()

func _on_slot_button_pressed(slot: int) -> void:
	if not SaveManager.has_save_data(slot):
		return
	close()
	SaveManager.load_game(slot)
	var loc := GameState.player_location
	ScreenManager.go_to_screen(loc["scene"], loc["entrance_id"])
