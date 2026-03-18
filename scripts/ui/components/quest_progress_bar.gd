extends HBoxContainer

@export var quest: Quest

func update_quest():
	if quest:
		$QuestLabel.text = quest.title
		$ProgressBar.max_value = quest.get_monster_count()
		update_bar()

func update_bar():
	$ProgressBar.value = clamp(quest.get_slain_count(), 0, quest.get_monster_count())
