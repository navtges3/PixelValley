extends HBoxContainer

var quest: Quest

func _ready() -> void:
	quest = GameState.current_quest
	$QuestLabel.text = quest.title
	$ProgressBar.max_value = quest.get_monster_count()
	update_bar()

func update_bar():
	$ProgressBar.value = clamp(quest.get_slain_count(), 0, quest.get_monster_count())
