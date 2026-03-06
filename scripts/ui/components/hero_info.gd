extends VBoxContainer
class_name HeroInfo

# Hero Name
@onready var name_label: Label = $NameLabel

# Progress Bars
@onready var health_bar: ProgressBar = $HeroBars/HealthBar
@onready var health_bar_label: Label = $HeroBars/HealthBar/HealthBarLabel
@onready var energy_bar: ProgressBar = $HeroBars/EnergyBar
@onready var energy_bar_label: Label = $HeroBars/EnergyBar/EnergyBarLabel
@onready var level_label: Label = $HeroBars/LevelLabel
@onready var xp_bar: ProgressBar = $HeroBars/XPBar

# Hero Stats
@onready var attack_label: Label = $HeroStats/AttackLabel
@onready var magic_label: Label = $HeroStats/MagicLabel
@onready var defense_label: Label = $HeroStats/DefenseLabel
@onready var resistance_label: Label = $HeroStats/ResistanceLabel
@onready var gold_label: Label = $HeroStats/GoldLabel

@export var hero: Hero:
	set(value):
		hero = value
		refresh()

func refresh() -> void:
	_update_text()
	_update_health_bar()
	_update_energy_bar()
	_update_xp_bar()

func _update_text() -> void:
	name_label.text = hero.name
	level_label.text = "Level: " + str(hero.level)
	attack_label.text = "Atk: " + str(hero.stat_block.attack)
	magic_label.text = "Mag: " + str(hero.stat_block.magic)
	defense_label.text = "Def: " + str(hero.stat_block.defense)
	resistance_label.text = "Res: " + str(hero.stat_block.resistance)
	gold_label.text = "Gold: " + str(hero.inventory.gold)

func _update_health_bar():
	var value = hero.stat_block.current_hp
	var max_value = hero.stat_block.max_hp
	health_bar.max_value = max_value
	health_bar.value = value
	health_bar_label.text = "%d / %d" % [value, max_value]

func _update_energy_bar():
	var value = hero.stat_block.current_nrg
	var max_value = hero.stat_block.max_nrg
	energy_bar.max_value = max_value
	energy_bar.value = value
	energy_bar_label.text = "%d / %d" % [value, max_value]

func _update_xp_bar():
	var value = hero.experience
	var max_value = hero.level * hero.LEVEL_UP_MULT
	xp_bar.max_value = max_value
	xp_bar.value = value
