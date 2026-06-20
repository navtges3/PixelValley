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
@onready var resist_label: Label = $HeroStats/ResistLabel
@onready var gold_label: Label = $HeroStats/GoldLabel

@export var hero: Hero:
	set(value):
		hero = value
		refresh()

func refresh() -> void:
	if hero == null:
		return
	_update_text()
	_update_health_bar()
	_update_energy_bar()
	_update_xp_bar()

func _update_text() -> void:
	name_label.text = hero.name
	level_label.text = "Level: " + str(hero.level)
	attack_label.text = "Atk: " + str(hero.attack)
	magic_label.text = "Mag: " + str(hero.magic)
	defense_label.text = "Def: " + str(hero.defense)
	resist_label.text = "Res: " + str(hero.resist)
	gold_label.text = "Gold: " + str(hero.inventory.gold)

func _update_health_bar() -> void:
	var value: int = hero.current_hp
	var max_value: int = hero.max_hp
	_refresh_labeled_bar(health_bar, health_bar_label, value, max_value, "%d / %d", HudBarStyle.hp_color(value, max_value))

func _update_energy_bar() -> void:
	var value: int = hero.current_nrg
	var max_value: int = hero.max_nrg
	_refresh_labeled_bar(energy_bar, energy_bar_label, value, max_value, "%d / %d", HudBarStyle.COLOR_NRG)

func _update_xp_bar() -> void:
	var value: int = hero.experience
	var max_value: int = hero.level * hero.LEVEL_UP_MULT
	_refresh_bar(xp_bar, value, max_value, HudBarStyle.COLOR_XP)

func _refresh_labeled_bar(bar: ProgressBar, label: Label, value: int, max_value: int, fmt: String, color: Color) -> void:
	_refresh_bar(bar, value, max_value, color)
	label.text = fmt % [value, max_value]

func _refresh_bar(bar: ProgressBar, value: int, max_value: int, color: Color) -> void:
	bar.max_value = max(max_value, 1)
	bar.value = value
	_set_bar_color(bar, color)

func _set_bar_color(bar: ProgressBar, color: Color) -> void:
	HudBarStyle.apply(bar, color)
