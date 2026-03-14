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
	var monster_text := ""
	for objective in quest.monster_objectives:
		monster_text += "%s: %d/%d\n" % [MonsterLoader.get_monster_name(objective.monster_id), objective.current_amount, objective.target_amount]
	$VBoxContainer/HBoxContainer/MonstersLabel.text = monster_text.strip_edges()

	call_deferred("_update_size")

func get_quest() -> Quest:
	return self.quest

func _update_size():
	custom_minimum_size.y = $VBoxContainer.get_combined_minimum_size().y + Y_OFFSET

func _pressed() -> void:
	emit_signal("quest_selected", self)
