extends Window

const GREEN_BUTTON = preload("uid://cgbnpl6hlm7s2")
const RED_BUTTON = preload("uid://130ubmqd1h3b")

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

func _ready() -> void:
	exclusive = true
	for i in slot_buttons.size():
		var slot_index = i + 1
		slot_buttons[i].pressed.connect(func(): _on_slot_button_pressed(slot_index))
		delete_buttons[i].pressed.connect(func(): _on_delete_button_pressed(slot_index))
	populate_slots()

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

func _on_slot_button_pressed(slot: int) -> void:
	if not SaveManager.has_save_data(slot):
		return
	self.hide()
	SaveManager.load_game(slot)
	var loc := GameState.player_location
	ScreenManager.go_to_screen(loc["scene"], loc["entrance_id"])

func _on_delete_button_pressed(slot: int) -> void:
	SaveManager.delete_slot(slot)
	populate_slots()

func setup_empty_slot(button: Button) -> void:
	button.text = "Empty Slot"
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.theme = RED_BUTTON

func setup_filled_slot(button: Button, meta: Dictionary) -> void:
	var hero_name = meta.get("hero_name", "Unknown")
	var level = meta.get("level", 1)
	var last_played = meta.get("time", "Unknown")
	button.text = "%s\nLevel: %d\nLast Played: %s" % [hero_name, level, last_played]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.theme = GREEN_BUTTON

func _on_back_button_pressed():
	self.hide()
