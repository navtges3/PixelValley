extends Button
class_name QuestButton

const Y_OFFSET := 16

signal quest_selected(quest_data)

var selected := false
@export var quest: Quest:
	set(value):
		quest = value
		_update_quest()

func _update_quest() -> void:
	$VBoxContainer/TitleLabel.text = quest.title
	$VBoxContainer/HBoxContainer/DescriptionLabel.text = quest.description
	var objective_lines: Array[String] = []
	for objective: QuestObjective in quest.objectives:
		objective_lines.append(objective.get_progress_text())
	$VBoxContainer/HBoxContainer/MonstersLabel.text = "\n".join(objective_lines)
	call_deferred("_update_size")

func get_quest() -> Quest:
	return self.quest

func _update_size() -> void:
	custom_minimum_size.y = $VBoxContainer.get_combined_minimum_size().y + Y_OFFSET

func _pressed() -> void:
	emit_signal("quest_selected", self)
