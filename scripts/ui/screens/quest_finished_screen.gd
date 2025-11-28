extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var reward_label: Label = $VBoxContainer/RewardLabel
@onready var continue_button: Button = $VBoxContainer/ContinueButton

func _ready() -> void:
	var current_quest = GameState.current_quest
	title_label.text = current_quest.title

	status_label.text = "Completed"
	var reward_text = ""
	for reward in current_quest.reward:
		reward_text += reward.get_description() + "\n"
	reward_label.text = reward_text.strip_edges()

func _on_continue_button_pressed() -> void:
	ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE)
