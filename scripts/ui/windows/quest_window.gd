extends Control
class_name QuestWindow

signal closed

@onready var available_button: Button = $PanelContainer/VBoxContainer/QuestTabs/AvailableButton
@onready var completed_button: Button = $PanelContainer/VBoxContainer/QuestTabs/CompletedButton
@onready var quest_list_v_box: VBoxContainer = $PanelContainer/VBoxContainer/QuestScrollContainer/QuestListVBox
@onready var turn_in_button: Button = $PanelContainer/VBoxContainer/BottomControls/TurnInButton
@onready var reward_window: Window = $RewardWindow

const QUEST_BUTTON := preload("res://scenes/ui/components/quest_button.tscn")

var selected_quest: QuestButton = null
var current_tab: String = "available"

func open() -> void:
	current_tab = "available"
	selected_quest = null
	available_button.button_pressed = true
	completed_button.button_pressed = false
	_update_complete_button()
	load_quests(current_tab)
	show()

func close() -> void:
	hide()
	closed.emit()

func _on_close_button_pressed() -> void:
	close()

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

func _on_turn_in_button_pressed() -> void:
	if selected_quest == null:
		return
	var quest: Quest = selected_quest.get_quest()
	if quest.all_objectives_met():
		var entries: Array[RewardEntry] = GameState.quest_manager.turn_in_quest(quest)
		reward_window.show_rewards("Quest Complete!", entries)
		selected_quest = null
		_update_complete_button()

func _on_rewards_collected() -> void:
	load_quests(current_tab)

func _on_quest_selected(selected_button: QuestButton) -> void:
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

func clear_quest_list() -> void:
	for child in quest_list_v_box.get_children():
		child.queue_free()

func load_quests(type: String) -> void:
	clear_quest_list()
	var quests: Array[Quest] = GameState.quest_manager.available_quests if type == "available" else GameState.quest_manager.completed_quests
	for quest: Quest in quests:
		var quest_button := QUEST_BUTTON.instantiate() as QuestButton
		quest_button.quest = quest
		quest_button.quest_selected.connect(_on_quest_selected)
		quest_list_v_box.add_child(quest_button)
