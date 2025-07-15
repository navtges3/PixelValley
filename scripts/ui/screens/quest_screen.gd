extends Control

@onready var quest_list_vbox = $MarginContainer/VBoxContainer/QuestScrollContainer/QuestListVBox
@onready var available_button = $MarginContainer/VBoxContainer/QuestTabs/AvaiableButton
@onready var complete_button = $MarginContainer/VBoxContainer/QuestTabs/CompleteButton
@onready var failed_button = $ MarginContainer/VBoxContainer/QuestTabs/FailedButton

@onready var start_button = $MarginContainer/VBoxContainer/BottomControls/StartButton
@onready var back_button = $MarginContainer/VBoxContainer/BottomControls/BackButton

@onready var pause_button = $MarginContainer/VBoxContainer/QuestTabs/PauseButton
@onready var pause_popup = $PausePopup

var selected_quest = null
var current_tab = "available"

func _ready() -> void:
	load_quests(current_tab)
	start_button.disabled = true
	available_button.toggled.connect(_on_available_toggled)
	complete_button.toggled.connect(_on_complete_toggled)
	failed_button.toggled.connect(_on_failed_toggled)
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	available_button.button_pressed = true

func clear_quest_list():
	for child in quest_list_vbox.get_children():
		child.queue_free()

func load_quests(type: String):
	clear_quest_list()
	var quests = QuestDatabase.get_quests_by_type(type)
	for quest in quests:
		var quest_button = preload("res://scenes/ui/components/quest_button.tscn").instantiate()
		quest_button.set_data(quest)
		quest_button.connect("quest_selected", _on_quest_selected)
		quest_list_vbox.add_child(quest_button)

func _on_quest_selected(selected_button: QuestButton):
	var quest = selected_button.get_quest()
	if not quest.is_complete():
		selected_quest = selected_button
		start_button.disabled = false
		for child in quest_list_vbox.get_children():
			if child is QuestButton:
				child.set_selected(child == selected_quest)

func _on_available_toggled(button_pressed: bool):
	if button_pressed:
		if current_tab != "available":
			current_tab = "available"
			complete_button.button_pressed = false
			failed_button.button_pressed = false
			load_quests(current_tab)

func _on_complete_toggled(button_pressed: bool):
	if button_pressed:
		if current_tab != "complete":
			current_tab = "complete"
			available_button.button_pressed = false
			failed_button.button_pressed = false
			load_quests(current_tab)

func _on_failed_toggled(button_pressed: bool):
	if button_pressed:
		if current_tab != "failed":
			current_tab = "failed"
			available_button.button_pressed = false
			complete_button.button_pressed = false
			load_quests(current_tab)

func _on_back_pressed():
	ScreenManager.go_to_screen("village")

func _on_start_pressed():
	if selected_quest:
		var quest = selected_quest.get_quest()
		GameState.current_quest = quest
		ScreenManager.go_to_screen("battle")

func _on_pause_pressed():
	pause_popup.popup_centered()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not pause_popup.is_visible():
		_on_pause_pressed()
