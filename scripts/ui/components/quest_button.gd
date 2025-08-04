extends Button
class_name QuestButton

const Y_OFFSET := 16

signal quest_selected(quest_data)

var quest: Quest
var selected := false

func set_data(q: Quest):
	quest = q
	$VBoxContainer/TitleLabel.text = q.title
	$VBoxContainer/HBoxContainer/DescriptionLabel.text = q.description

	var monster_text := ""
	for objective in q.monster_objectives:
		monster_text += "%s: %d/%d\n" % [objective.monster.name, objective.current_amount, objective.target_amount]
	$VBoxContainer/HBoxContainer/MonstersLabel.text = monster_text.strip_edges()
	
	call_deferred("_update_size")

func get_quest() -> Quest:
	return self.quest

func _update_size():
	custom_minimum_size.y = $VBoxContainer.get_combined_minimum_size().y + Y_OFFSET

func _pressed() -> void:
	emit_signal("quest_selected", self)

func set_selected(value: bool) -> void:
	selected = value
	var style = StyleBoxFlat.new()
	self.add_theme_stylebox_override("MarginContainer", style)
