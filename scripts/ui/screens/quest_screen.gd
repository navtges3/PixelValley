extends Control

@onready var available_button: Button = $MarginContainer/VBoxContainer/QuestTabs/AvailableButton
@onready var complete_button: Button = $MarginContainer/VBoxContainer/QuestTabs/CompleteButton
@onready var quest_list_vbox: VBoxContainer = $MarginContainer/VBoxContainer/QuestScrollContainer/QuestListVBox

@onready var start_button: Button = $MarginContainer/VBoxContainer/BottomControls/StartButton

var selected_quest:Button = null
var current_tab = "available"

func _ready() -> void:
	load_quests(current_tab)
	start_button.disabled = true
	available_button.button_pressed = true

func clear_quest_list():
	for child in quest_list_vbox.get_children():
		child.queue_free()

func load_quests(type: String):
	clear_quest_list()
	var quests = GameState.quest_manager.available_quests if type == "available" else GameState.quest_manager.completed_quests
	for quest in quests:
		var quest_button = preload("res://scenes/ui/components/quest_button.tscn").instantiate()
		quest_button.quest = quest
		quest_button.connect("quest_selected", _on_quest_selected)
		quest_list_vbox.add_child(quest_button)

func _on_quest_selected(selected_button: QuestButton):
	if selected_quest == selected_button:
		selected_quest = null
		start_button.disabled = true
	elif not selected_button.quest.is_complete():
		if selected_quest:
			selected_quest.button_pressed = false
		selected_quest = selected_button
		start_button.disabled = false

func _on_available_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if current_tab != "available":
			current_tab = "available"
			complete_button.button_pressed = false
			load_quests(current_tab)

func _on_complete_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if current_tab != "complete":
			current_tab = "complete"
			available_button.button_pressed = false
			if selected_quest:
				selected_quest.button_pressed = false
				selected_quest = null
			start_button.disabled = true
			load_quests(current_tab)

func _on_back_button_pressed() -> void:
	ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE)

func _on_start_button_pressed() -> void:
	if selected_quest:
		GameState.current_quest = selected_quest.get_quest()
		var config := BattleConfig.new()
		config.hero = GameState.hero
		config.quest = GameState.current_quest
		config.is_test_battle = false
		ScreenManager.go_to_screen(ScreenManager.ScreenName.BATTLE, config)
