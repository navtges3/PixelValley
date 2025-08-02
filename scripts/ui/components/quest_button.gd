extends Button
class_name QuestButton

signal quest_selected(quest_data)

@export var default_theme: Theme
@export var selected_theme: Theme

@onready var title: Label = $MarginContainer/HBoxContainer/VBoxContainer/Title
@onready var reward: Label = $MarginContainer/HBoxContainer/VBoxContainer/Reward
@onready var description: Label = $MarginContainer/HBoxContainer/Description
@onready var monsters: Label = $MarginContainer/HBoxContainer/Monsters

var quest: Quest
var selected := false

func set_data(q: Quest):
	quest = q
	$MarginContainer/HBoxContainer/VBoxContainer/Title.text = q.title
	$MarginContainer/HBoxContainer/Description.text = q.description
	var reward_text := ""
	for r in q.reward:
		reward_text += r.get_description() + "\n"
	$MarginContainer/HBoxContainer/VBoxContainer/Reward.text = reward_text.strip_edges()
	var monster_text := ""
	for objective in q.monster_objectives:
		monster_text += "%s: %d/%d\n" % [objective.monster.name, objective.current_amount, objective.target_amount]
	$MarginContainer/HBoxContainer/Monsters.text = monster_text.strip_edges()

func get_quest() -> Quest:
	return self.quest

func _pressed() -> void:
	emit_signal("quest_selected", self)

func set_selected(value: bool) -> void:
	selected = value
	var style = StyleBoxFlat.new()
	if selected:
		self.theme = selected_theme
	else:
		self.theme = default_theme

	self.add_theme_stylebox_override("MarginContainer", style)
