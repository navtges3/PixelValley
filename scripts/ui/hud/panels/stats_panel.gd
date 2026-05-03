extends Control
class_name StatsPanel

@onready var name_label: Label = $ScrollContainer/VBox/NameRow/NameLabel
@onready var class_label: Label = $ScrollContainer/VBox/NameRow/ClassLabel
@onready var level_label: Label = $ScrollContainer/VBox/LevelRow/LevelLabel
@onready var skill_label: Label = $ScrollContainer/VBox/LevelRow/SkillLabel

@onready var hp_bar: ProgressBar = $ScrollContainer/VBox/HPBar
@onready var hp_label: Label = $ScrollContainer/VBox/HPBar/HPLabel
@onready var nrg_bar: ProgressBar = $ScrollContainer/VBox/NRGBar
@onready var nrg_label: Label = $ScrollContainer/VBox/NRGBar/NRGLabel
@onready var xp_bar: ProgressBar = $ScrollContainer/VBox/XPBar
@onready var xp_label: Label = $ScrollContainer/VBox/XPBar/XPLabel

@onready var attack_label: Label = $ScrollContainer/VBox/StatsGrid/AttackLabel
@onready var magic_label: Label = $ScrollContainer/VBox/StatsGrid/MagicLabel
@onready var defense_label: Label = $ScrollContainer/VBox/StatsGrid/DefenseLabel
@onready var resist_label: Label = $ScrollContainer/VBox/StatsGrid/ResistLabel
@onready var gold_label: Label = $ScrollContainer/VBox/StatsGrid/GoldLabel

@onready var effects_container: VBoxContainer = $ScrollContainer/VBox/EffectsContainer

const COLOR_HP_HIGH  := Color(0.25, 0.78, 0.35)
const COLOR_HP_MID   := Color(0.9,  0.72, 0.15)
const COLOR_HP_LOW   := Color(0.85, 0.22, 0.18)
const COLOR_NRG      := Color(0.35, 0.55, 0.9)
const COLOR_XP       := Color(0.55, 0.35, 0.85)
const COLOR_GOLD     := Color(0.95, 0.80, 0.25)
const COLOR_HEADER   := Color(0.95, 0.92, 0.80)
const COLOR_SUBTEXT  := Color(0.72, 0.67, 0.57)

func refresh() -> void:
	if GameState.hero == null:
		return
	var hero := GameState.hero
	
	name_label.text = hero.name
	name_label.add_theme_color_override("font_color", COLOR_HEADER)
	class_label.text = hero.get_class_name()
	class_label.add_theme_color_override("font_color", COLOR_SUBTEXT)
	
	level_label.text = "Level %d" % hero.level
	level_label.add_theme_color_override("font_color", COLOR_HEADER)
	skill_label.text = "Skill Points: %d" % hero.skill_points
	skill_label.add_theme_color_override("font_color", COLOR_GOLD)
 
	_refresh_bar(hp_bar, hp_label, hero.current_hp, hero.max_hp,"%d / %d HP", _hp_color(hero.current_hp, hero.max_hp))
	_refresh_bar(nrg_bar, nrg_label, hero.current_nrg, hero.max_nrg,"%d / %d NRG", COLOR_NRG)
	_refresh_bar(xp_bar, xp_label, hero.experience, hero.level * Hero.LEVEL_UP_MULT,"%d / %d XP", COLOR_XP)
 
	attack_label.text  = "⚔ Attack: %d" % hero.attack
	magic_label.text   = "✦ Magic: %d"  % hero.magic
	defense_label.text = "🛡 Defense: %d"   % hero.defense
	resist_label.text  = "◈ Resist: %d"   % hero.resistance
	gold_label.text    = "⬡ Gold: %d"   % hero.inventory.gold
	gold_label.add_theme_color_override("font_color", COLOR_GOLD)
 
	_refresh_effects(hero)

func _refresh_bar(bar: ProgressBar, label: Label, value: int, max_val: int, fmt: String, color: Color) -> void:
	bar.max_value = max(max_val, 1)
	bar.value = value
	label.text = fmt % [value, max_val]
	_set_bar_color(bar, color)

func _refresh_effects(hero: Hero) -> void:
	for child in effects_container.get_children():
		child.queue_free()
	
	if hero.active_effects.is_empty():
		var lbl := _make_label("No active effects", COLOR_SUBTEXT, 11)
		effects_container.add_child(lbl)
		return
	
	var header := _make_label("Active Effects:", COLOR_HEADER, 12)
	effects_container.add_child(header)
	for ae in hero.active_effects:
		var lbl := _make_label("  • %s" % ae._to_string(), COLOR_SUBTEXT, 11)
		effects_container.add_child(lbl)

func _hp_color(current: int, maximum: int) -> Color:
	if maximum <= 0:
		return COLOR_HP_HIGH
	var ratio := float(current) / float(maximum)
	if ratio > 0.5:
		return COLOR_HP_HIGH
	elif ratio > 0.25:
		return COLOR_HP_MID
	return COLOR_HP_LOW

func _set_bar_color(bar: ProgressBar, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", style)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.10, 0.08, 0.8)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg)

func _make_label(txt: String, color: Color, font_size: int = 12) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	return lbl
