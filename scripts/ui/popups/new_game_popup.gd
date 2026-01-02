extends PopupPanel

const GREEN_BUTTON = preload("uid://cgbnpl6hlm7s2")
const RED_BUTTON = preload("uid://130ubmqd1h3b")

@onready var slot_buttons: Array[Button] = [
	$VBoxContainer/SlotButton1,
	$VBoxContainer/SlotButton2,
	$VBoxContainer/SlotButton3,
	$VBoxContainer/SlotButton4,
	$VBoxContainer/SlotButton5
]
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	populate_slots()

func populate_slots() -> void:
	for i in slot_buttons.size():
		var button := slot_buttons[i]
		var slot_index := i + 1
		var meta := SaveManager.get_save_meta(slot_index)
		
		if meta.is_empty():
			setup_empty_slot(button)
		else:
			setup_filled_slot(button, meta)
		button.pressed.connect(func():
			GameState.start_new_game(slot_index)
			ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE)
		)

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

func _on_back_button_pressed() -> void:
	self.hide()
