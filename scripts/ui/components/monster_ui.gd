extends HBoxContainer
class_name MonsterUI

@onready var picture = $Visual/Picture
@onready var health_bar = $Visual/HealthBar
@onready var health_label = $Visual/HealthBar/HealthLabel
@onready var name_label = $Stats/NameLabel
@onready var level_label = $Stats/LevelLabel

var monster: Monster

func set_monster_info(monster_ref: Monster):
	monster = monster_ref
	refresh()

func refresh() -> void:
	picture.texture = monster.portrait
	name_label.text = monster.name
	level_label.text = "Level: " + str(monster.level)
	update_health_bar()

func update_health_bar():
	var value = monster.current_hp
	var max_value = monster.max_hp
	health_bar.max_value = max_value
	health_bar.value = value
	health_label.text = "%d / %d" % [value, max_value]