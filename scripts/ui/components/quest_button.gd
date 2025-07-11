extends Button
class_name QuestButton

signal quest_selected(quest_data)

@export var default_theme: Theme
@export var selected_theme: Theme

var quest: Quest
var selected := false

func set_data(q: Quest):
	self.quest = q

	$MarginContainer/HBoxContainer/VBoxContainer/Title.text = self.quest.title
	$MarginContainer/HBoxContainer/VBoxContainer/Reward.text = self.quest.reward
	$MarginContainer/HBoxContainer/Description.text = self.quest.description

	var obj_text = ""
	for enemy in self.quest.monsters.keys():
		obj_text += "%s %s/%s\n" % [enemy, self.quest.monsters[enemy]["slain"], self.quest.monsters[enemy]["objective"]]
	$MarginContainer/HBoxContainer/Monsters.text = obj_text.strip_edges()

	var penalty_text = ""
	for penalty_name in self.quest.penalty.keys():
		penalty_text += "%s: -%s\n" % [penalty_name, self.quest.penalty[penalty_name]]
	$MarginContainer/HBoxContainer/VBoxContainer/Penalty.text = penalty_text.strip_edges()

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
