extends HBoxContainer
class_name HeroUI

@onready var picture = $Visuals/Picture
@onready var health_bar = $Visuals/Bars/HealthBar
@onready var health_label = $Visuals/Bars/HealthBar/HealthLabel
@onready var energy_bar = $Visuals/Bars/EnergyBar
@onready var energy_label = $Visuals/Bars/EnergyBar/EnergyLabel
@onready var name_label = $Stats/NameLabel
@onready var class_label = $Stats/ClassLabel
@onready var weapon_label = $Stats/WeaponLabel
@onready var level_label = $Stats/LevelLabel
@onready var experience_label = $Stats/XPLabel
@onready var active_effects_label = $Stats/ActiveEffectsLabel

var hero: HeroInstance = null

func set_hero_info(hero_ref: HeroInstance):
	hero = hero_ref
	refresh()

func refresh() -> void:
	name_label.text = hero.hero_name
	class_label.text = hero.hero_class.hero_class_name
	picture.texture = hero.hero_class.portrait
	weapon_label.text = hero.weapon.name
	level_label.text = "Level: " + str(hero.level)
	experience_label.text = "XP: " + str(hero.experience)
	update_health_bar()
	update_energy_bar()
	update_active_effects()

func update_health_bar():
	var value = hero.current_hp
	var max_value = hero.max_hp
	health_bar.max_value = max_value
	health_bar.value = value
	health_label.text = "%d / %d" % [value, max_value]

func update_energy_bar():
	var value = hero.current_nrg
	var max_value = hero.max_nrg
	energy_bar.max_value = max_value
	energy_bar.value = value
	energy_label.text = "%d / %d" % [value, max_value]

func update_active_effects():
	var active_effects_text = "Active Effects: "
	if hero.active_effects.size() == 0:
		active_effects_text += "None"
	else:
		for effect in hero.active_effects:
			active_effects_text += "\n%s (Strength: %s, Duration: %s)" % [str(effect.effect), str(effect.strength), str(effect.duration)]
	active_effects_label.text = active_effects_text