extends Control

const LOCATION_ID := "quest"

@onready var available_button: Button = $MarginContainer/PanelContainer/VBoxContainer/QuestTabs/AvailableButton
@onready var completed_button: Button = $MarginContainer/PanelContainer/VBoxContainer/QuestTabs/CompletedButton
@onready var quest_list_v_box: VBoxContainer = $MarginContainer/PanelContainer/VBoxContainer/QuestScrollContainer/QuestListVBox

@onready var turn_in_button: Button = $MarginContainer/PanelContainer/VBoxContainer/BottomControls/TurnInButton
@onready var reward_window: Window = $RewardWindow

var selected_quest: QuestButton = null
var current_tab = "available"

func _ready() -> void:
	load_quests(current_tab)
	available_button.button_pressed = true
	_update_complete_button()

func _on_back_button_pressed() -> void:
	ScreenManager.go_back(LOCATION_ID)

func _on_completed_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if current_tab != "completed":
			current_tab = "completed"
			available_button.button_pressed = false
			if selected_quest:
				selected_quest.button_pressed = false
				selected_quest = null
			_update_complete_button()
			load_quests(current_tab)
	else:
		available_button.button_pressed = true
		_on_available_button_toggled(not toggled_on)

func _on_available_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if current_tab != "available":
			current_tab = "available"
			completed_button.button_pressed = false
			load_quests(current_tab)
	else:
		completed_button.button_pressed = true
		_on_completed_button_toggled(not toggled_on)

func _on_start_button_pressed() -> void:
	if selected_quest == null:
		return
	var quest: Quest = selected_quest.get_quest()
	if quest.all_objectives_met():
		var entries := GameState.quest_manager.turn_in_quest(quest)
		reward_window.show_rewards("Quest Complete!", entries)
		selected_quest = null
		_update_complete_button()

func _on_rewards_collected() -> void:
	load_quests(current_tab)

func _on_quest_selected(selected_button: QuestButton):
	if selected_quest == selected_button:
		selected_quest = null
		_update_complete_button()
	else:
		if current_tab == "completed":
			return
		if selected_quest:
			selected_quest.button_pressed = false
		selected_quest = selected_button
		_update_complete_button()

func _update_complete_button() -> void:
	if selected_quest:
		var objectives_met: bool = selected_quest.get_quest().all_objectives_met()
		turn_in_button.disabled = not objectives_met
		turn_in_button.text = "Turn In" if objectives_met else "In Progress"
	else:
		turn_in_button.disabled = true
		turn_in_button.text = "Locked"

func clear_quest_list():
	for child in quest_list_v_box.get_children():
		child.queue_free()

func load_quests(type: String):
	clear_quest_list()
	var quests = GameState.quest_manager.available_quests if type == "available" else GameState.quest_manager.completed_quests
	for quest in quests:
		var quest_button = preload("res://scenes/ui/components/quest_button.tscn").instantiate()
		quest_button.quest = quest
		quest_button.connect("quest_selected", _on_quest_selected)
		quest_list_v_box.add_child(quest_button)
