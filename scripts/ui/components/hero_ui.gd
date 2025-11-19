extends HBoxContainer
class_name HeroUI

@onready var picture = $Visuals/Picture
@onready var health_bar = $Visuals/Bars/HealthBar
@onready var health_label = $Visuals/Bars/HealthBar/HealthLabel
@onready var energy_bar = $Visuals/Bars/EnergyBar
@onready var energy_label = $Visuals/Bars/EnergyBar/EnergyLabel
@onready var name_label = $HeroInfo/NameLabel
@onready var class_label = $HeroInfo/ClassLabel
@onready var level_label = $HeroInfo/GridContainer/LevelLabel
@onready var experience_label = $HeroInfo/GridContainer/XPLabel
@onready var attack_label: Label = $HeroInfo/GridContainer/AttackLabel
@onready var magic_label: Label = $HeroInfo/GridContainer/MagicLabel
@onready var defense_label: Label = $HeroInfo/GridContainer/DefenseLabel
@onready var resistance_label: Label = $HeroInfo/GridContainer/ResistanceLabel

@onready var gold_label = $HeroInfo/GoldLabel
@onready var weapon_label = $HeroInfo/WeaponLabel
@onready var active_effects_label = $HeroInfo/ActiveEffectsLabel

@export var hero: Hero:
	set(value):
		hero = value
		refresh()

func refresh() -> void:
	_update_text()
	_update_health_bar()
	_update_energy_bar()
	_update_active_effects()

func _update_text() -> void:
	name_label.text = hero.name
	class_label.text = "Class: " + hero.hero_class
	picture.texture = hero.portrait
	level_label.text = "Level: " + str(hero.level)
	experience_label.text = "XP: " + str(hero.experience)
	attack_label.text = "Atk: " + str(hero.stat_block.attack)
	magic_label.text = "Mag: " + str(hero.stat_block.magic)
	defense_label.text = "Def: " + str(hero.stat_block.defense)
	resistance_label.text = "Res: " + str(hero.stat_block.resistance)
	gold_label.text = "Gold: " + str(hero.inventory.gold)
	weapon_label.text = hero.inventory.equipped_weapon.name

func _update_health_bar():
	var value = hero.stat_block.current_hp
	var max_value = hero.stat_block.max_hp
	health_bar.max_value = max_value
	health_bar.value = value
	health_label.text = "%d / %d" % [value, max_value]

func _update_energy_bar():
	var value = hero.stat_block.current_nrg
	var max_value = hero.stat_block.max_nrg
	energy_bar.max_value = max_value
	energy_bar.value = value
	energy_label.text = "%d / %d" % [value, max_value]

func _update_active_effects():
	var active_effects_text = "Active Effects: "
	if hero.active_effects.size() == 0:
		active_effects_text += "\n -None"
	else:
		for ae in hero.active_effects:
			active_effects_text += "\n -%s" % ae.get_tooltip()
	active_effects_label.text = active_effects_text
