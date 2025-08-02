extends Control

@onready var village_button = $VBoxContainer/HBoxContainer/VillageButton
@onready var new_quest_button = $VBoxContainer/HBoxContainer/NewQuestButton

@onready var title_label = $VBoxContainer/TitleLabel
@onready var status_label = $VBoxContainer/StatusLabel
@onready var result_label = $VBoxContainer/ResultLabel

func _ready() -> void:
	var current_quest = GameState.current_quest
	title_label.text = current_quest.title

	status_label.text = "Completed"
	var reward_text = ""
	for reward in current_quest.reward:
		reward_text += reward.get_description() + "\n"
	result_label.text = reward_text.strip_edges()

	village_button.pressed.connect(_on_village_button_pressed)
	new_quest_button.pressed.connect(_on_new_quest_button_pressed)

func _on_village_button_pressed() -> void:
	ScreenManager.go_to_screen("village")

func _on_new_quest_button_pressed() -> void:
	ScreenManager.go_to_screen("quest")
