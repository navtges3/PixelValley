extends Control

@onready var save_buttons := [
	$VBoxContainer/GridContainer/SaveSlotButton1,
	$VBoxContainer/GridContainer/SaveSlotButton2,
	$VBoxContainer/GridContainer/SaveSlotButton3
]

@onready var delete_buttons := [
	$VBoxContainer/GridContainer/DeleteSlotButton1,
	$VBoxContainer/GridContainer/DeleteSlotButton2,
	$VBoxContainer/GridContainer/DeleteSlotButton3
]

@onready var back_button := $VBoxContainer/BackButton

func _ready() -> void:
	update_slots()

	for i in save_buttons.size():
		var button = save_buttons[i]
		button.pressed.connect(_on_slot_pressed.bind(i + 1))

	for i in delete_buttons.size():
		var button = delete_buttons[i]
		button.pressed.connect(_on_delete_pressed.bind(i + 1))

	back_button.pressed.connect(_on_back_button_pressed)

func update_slots():
	var available_slots = GameState.get_available_save_slots(3)

	for i in range(save_buttons.size()):
		var slot_num = i + 1
		var button = save_buttons[i]

		if slot_num in available_slots:
			button.text = "Load Slot %d" % slot_num
			button.disabled = false
		else:
			button.text = "Empty Slot %d" % slot_num
			button.disabled = true

func _on_slot_pressed(slot: int) -> void:
	GameState.load_game(slot)
	get_tree().change_scene_to_file("res://scenes/ui/screens/village_screen.tscn")

func _on_delete_pressed(slot: int) -> void:
	GameState.delete_save(slot)
	update_slots()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/screens/main_menu_screen.tscn")

