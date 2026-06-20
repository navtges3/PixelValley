extends Control
class_name HeroHUD

@onready var name_label: Label = $PanelBG/MarginContainer/VBoxContainer/NameRow/NameLabel
@onready var class_label: Label = $PanelBG/MarginContainer/VBoxContainer/NameRow/ClassLabel
@onready var level_label: Label = $PanelBG/MarginContainer/VBoxContainer/LevelRow/LevelLabel
@onready var skill_label: Label = $PanelBG/MarginContainer/VBoxContainer/SkillLabel
@onready var gold_label: Label = $PanelBG/MarginContainer/VBoxContainer/LevelRow/GoldLabel
@onready var hp_bar: ProgressBar = $PanelBG/MarginContainer/VBoxContainer/HPBar
@onready var hp_label: Label = $PanelBG/MarginContainer/VBoxContainer/HPBar/HPLabel
@onready var xp_bar: ProgressBar = $PanelBG/MarginContainer/VBoxContainer/XPBar
@onready var xp_label: Label = $PanelBG/MarginContainer/VBoxContainer/XPBar/XPLabel

var _last_hp: int = -1
var _last_max_hp: int = -1
var _last_xp: int = -1
var _last_level: int = -1
var _last_skill: int = -1
var _last_gold: int = -1

const COLOR_GOLD     := Color(0.95, 0.80, 0.25)
const COLOR_NAME     := Color(0.95, 0.92, 0.80)
const COLOR_CLASS    := Color(0.70, 0.65, 0.55)
const COLOR_LEVEL    := Color(0.95, 0.92, 0.80)

func _ready() -> void:
	_apply_bar_styles()
	_force_refresh()

func _process(_delta: float) -> void:
	_refresh_if_dirty()

func _refresh_if_dirty() -> void:
	if GameState.hero == null:
		return
	var hero := GameState.hero
	
	var changed := (
		hero.current_hp != _last_hp or 
		hero.max_hp != _last_max_hp or
		hero.experience != _last_xp or 
		hero.level != _last_level or 
		hero.skill_points != _last_skill or 
		hero.inventory.gold != _last_gold
	)
	if not changed:
		return
	
	_last_hp = hero.current_hp
	_last_max_hp = hero.max_hp
	_last_xp = hero.experience
	_last_level = hero.level
	_last_skill = hero.skill_points
	_last_gold = hero.inventory.gold
	
	_draw_data(hero)

func _force_refresh() -> void:
	if GameState.hero == null:
		return
	var hero := GameState.hero
	
	name_label.text = hero.name
	class_label.text = hero.get_class_name()
	name_label.add_theme_color_override("font_color", COLOR_NAME)
	class_label.add_theme_color_override("font_color", COLOR_CLASS)
	
	_draw_data(hero)

func _draw_data(hero: Hero) -> void:
	name_label.text = hero.name
	level_label.text = "Lv %d" % hero.level
	skill_label.text = "Skill Points: %d" % hero.skill_points
	gold_label.text = "⬡ %d" % hero.inventory.gold
	level_label.add_theme_color_override("font_color", COLOR_LEVEL)
	skill_label.add_theme_color_override("font_color", COLOR_LEVEL)
	gold_label.add_theme_color_override("font_color", COLOR_GOLD)
	
	hp_bar.max_value = hero.max_hp
	hp_bar.value = hero.current_hp
	hp_label.text = "%d / %d" % [hero.current_hp, hero.max_hp]
	_set_bar_color(hp_bar, HudBarStyle.hp_color(hero.current_hp, hero.max_hp))
	
	var xp_needed: int = hero.level * Hero.LEVEL_UP_MULT
	xp_bar.max_value = xp_needed
	xp_bar.value = hero.experience
	xp_label.text = "%d / %d xp" % [hero.experience, xp_needed]

func _set_bar_color(bar: ProgressBar, color: Color) -> void:
	HudBarStyle.apply_fill(bar, color)


func _apply_bar_styles() -> void:
	# HP bar fill
	HudBarStyle.apply(hp_bar, HudBarStyle.COLOR_HP_HIGH)

	# XP bar fill
	HudBarStyle.apply(xp_bar, HudBarStyle.COLOR_XP)
