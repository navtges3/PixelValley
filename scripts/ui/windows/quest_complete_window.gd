extends Window

signal reward_collected(quest: Quest)

@onready var reward_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/RewardList

var _quest: Quest

func show_quest_complete(quest: Quest) -> void:
	_quest = quest
	
	# Clear any previously listed rewards
	for child in reward_list.get_children():
		child.queue_free()
	
	# Populate reward labels from QuestReward.get_description()
	for reward in quest.reward:
		var label := Label.new()
		label.text = reward.get_description()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_list.add_child(label)
	
	popup_centered()

func _on_collect_button_pressed() -> void:
	emit_signal("reward_collected", _quest)
	hide()
