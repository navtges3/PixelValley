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

const COLOR_HP_HIGH  := Color(0.25, 0.78, 0.35)   # green
const COLOR_HP_MID   := Color(0.9,  0.72, 0.15)   # yellow
const COLOR_HP_LOW   := Color(0.85, 0.22, 0.18)   # red
const COLOR_XP       := Color(0.35, 0.55, 0.9)    # blue
const COLOR_GOLD     := Color(0.95, 0.80, 0.25)   # gold
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
	var sb := hero.stat_block
	
	var changed := (
		sb.current_hp != _last_hp or 
		sb.max_hp != _last_max_hp or
		hero.experience != _last_xp or 
		hero.level != _last_level or 
		hero.skill_points != _last_skill or 
		hero.inventory.gold != _last_gold
	)
	if not changed:
		return
	
	_last_hp = sb.current_hp
	_last_max_hp = sb.max_hp
	_last_xp = hero.experience
	_last_level = hero.level
	_last_skill = hero.skill_points
	_last_gold = hero.inventory.gold
	
	_draw_data(hero, sb)

func _force_refresh() -> void:
	if GameState.hero == null:
		return
	var hero := GameState.hero
	var sb := hero.stat_block
	
	name_label.text = hero.name
	class_label.text = hero.get_class_name()
	name_label.add_theme_color_override("font_color", COLOR_NAME)
	class_label.add_theme_color_override("font_color", COLOR_CLASS)
	
	_draw_data(hero, sb)

func _draw_data(hero: Hero, sb: StatBlock) -> void:
	level_label.text = "Lv %d" % hero.level
	skill_label.text = "Skill Points: %d" % hero.skill_points
	gold_label.text = "⬡ %d" % hero.inventory.gold
	level_label.add_theme_color_override("font_color", COLOR_LEVEL)
	skill_label.add_theme_color_override("font_color", COLOR_LEVEL)
	gold_label.add_theme_color_override("font_color", COLOR_GOLD)
	
	hp_bar.max_value = sb.max_hp
	hp_bar.value = sb.current_hp
	hp_label.text = "%d / %d" % [sb.current_hp, sb.max_hp]
	_set_bar_color(hp_bar, _hp_color(sb.current_hp, sb.max_hp))
	
	var xp_needed: int = hero.level * Hero.LEVEL_UP_MULT
	xp_bar.max_value = xp_needed
	xp_bar.value = hero.experience
	xp_label.text = "%d / %d xp" % [hero.experience, xp_needed]

func _hp_color(current: int, maximum: int) -> Color:
	if maximum <= 0:
		return COLOR_HP_HIGH
	var ratio := float(current) / float(maximum)
	if ratio > 0.5:
		return COLOR_HP_HIGH
	elif ratio > 0.25:
		return COLOR_HP_MID
	else:
		return COLOR_HP_LOW

func _set_bar_color(bar: ProgressBar, color: Color) -> void:
	var style := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if style:
		style = style.duplicate()
		style.bg_color = color
		bar.add_theme_stylebox_override("fill", style)


func _apply_bar_styles() -> void:
	# HP bar fill
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = COLOR_HP_HIGH
	hp_fill.corner_radius_top_left    = 3
	hp_fill.corner_radius_top_right   = 3
	hp_fill.corner_radius_bottom_left = 3
	hp_fill.corner_radius_bottom_right = 3
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
 
	# HP bar background
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.15, 0.12, 0.10, 0.8)
	hp_bg.corner_radius_top_left    = 3
	hp_bg.corner_radius_top_right   = 3
	hp_bg.corner_radius_bottom_left = 3
	hp_bg.corner_radius_bottom_right = 3
	hp_bar.add_theme_stylebox_override("background", hp_bg)
 
	# XP bar fill
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = COLOR_XP
	xp_fill.corner_radius_top_left    = 3
	xp_fill.corner_radius_top_right   = 3
	xp_fill.corner_radius_bottom_left = 3
	xp_fill.corner_radius_bottom_right = 3
	xp_bar.add_theme_stylebox_override("fill", xp_fill)
 
	# XP bar background
	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.15, 0.12, 0.10, 0.8)
	xp_bg.corner_radius_top_left    = 3
	xp_bg.corner_radius_top_right   = 3
	xp_bg.corner_radius_bottom_left = 3
	xp_bg.corner_radius_bottom_right = 3
	xp_bar.add_theme_stylebox_override("background", xp_bg)
