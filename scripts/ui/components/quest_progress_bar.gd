extends HBoxContainer

var quest: Quest

func _ready() -> void:
	quest = GameState.current_quest
	$QuestLabel.text = quest.title
	$ProgressBar.max_value = quest.total_monsters
	update_bar()

func update_bar():
	$ProgressBar.value = clamp(quest.monsters_slain, 0, quest.total_monsters)