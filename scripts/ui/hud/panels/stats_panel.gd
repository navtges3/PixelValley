extends HudPanel
class_name StatsPanel

@onready var name_label: Label = $ScrollContainer/VBox/StatsRow/StatsBars/NameRow/NameLabel
@onready var class_label: Label = $ScrollContainer/VBox/StatsRow/StatsBars/NameRow/ClassLabel
@onready var level_label: Label = $ScrollContainer/VBox/StatsRow/StatsBars/LevelRow/LevelLabel

@onready var hp_bar: ProgressBar = $ScrollContainer/VBox/StatsRow/StatsBars/HPBar
@onready var hp_label: Label = $ScrollContainer/VBox/StatsRow/StatsBars/HPBar/HPLabel
@onready var nrg_bar: ProgressBar = $ScrollContainer/VBox/StatsRow/StatsBars/NRGBar
@onready var nrg_label: Label = $ScrollContainer/VBox/StatsRow/StatsBars/NRGBar/NRGLabel
@onready var xp_bar: ProgressBar = $ScrollContainer/VBox/StatsRow/StatsBars/XPBar
@onready var xp_label: Label = $ScrollContainer/VBox/StatsRow/StatsBars/XPBar/XPLabel

@onready var attack_label: Label = $ScrollContainer/VBox/StatsRow/StatsGrid/AttackLabel
@onready var magic_label: Label = $ScrollContainer/VBox/StatsRow/StatsGrid/MagicLabel
@onready var defense_label: Label = $ScrollContainer/VBox/StatsRow/StatsGrid/DefenseLabel
@onready var resist_label: Label = $ScrollContainer/VBox/StatsRow/StatsGrid/ResistLabel
@onready var gold_label: Label = $ScrollContainer/VBox/StatsRow/StatsBars/GoldLabel

@onready var attack_up: Button = $ScrollContainer/VBox/StatsRow/StatsGrid/AttackMod/AttackUp
@onready var attack_down: Button = $ScrollContainer/VBox/StatsRow/StatsGrid/AttackMod/AttackDown
@onready var magic_up: Button = $ScrollContainer/VBox/StatsRow/StatsGrid/MagicMod/MagicUp
@onready var magic_down: Button = $ScrollContainer/VBox/StatsRow/StatsGrid/MagicMod/MagicDown
@onready var defense_up: Button = $ScrollContainer/VBox/StatsRow/StatsGrid/DefenseMod/DefenseUp
@onready var defense_down: Button = $ScrollContainer/VBox/StatsRow/StatsGrid/DefenseMod/DefenseDown
@onready var resist_up: Button = $ScrollContainer/VBox/StatsRow/StatsGrid/ResistMod/ResistUp
@onready var resist_down: Button = $ScrollContainer/VBox/StatsRow/StatsGrid/ResistMod/ResistDown

@onready var confirm_button: Button = $ScrollContainer/VBox/StatsRow/StatsGrid/ConfirmButton
@onready var skill_label: Label = $ScrollContainer/VBox/StatsRow/StatsGrid/SkillLabel

@onready var effects_container: VBoxContainer = $ScrollContainer/VBox/EffectsContainer

const COLOR_BUFFED := Color(0.30, 0.90, 0.40)

var _up_buttons: Dictionary
var _down_buttons: Dictionary
var _stat_labels: Dictionary

var _temp_allocations := {
	"attack": 0,
	"magic": 0,
	"defense": 0,
	"resist": 0,
}
var _available_points := 0

func _ready() -> void:
	_up_buttons = {
		"attack": attack_up,
		"magic": magic_up,
		"defense": defense_up,
		"resist": resist_up,
	}
	_down_buttons = {
		"attack": attack_down,
		"magic": magic_down,
		"defense": defense_down,
		"resist": resist_down,
	}
	_stat_labels = {
		"attack": attack_label,
		"magic": magic_label,
		"defense": defense_label,
		"resist": resist_label,
	}

	for stat in _up_buttons:
		_up_buttons[stat].pressed.connect(_on_increase.bind(stat))
		_down_buttons[stat].pressed.connect(_on_decrease.bind(stat))

	confirm_button.pressed.connect(_on_confirm_pressed)

# ---- HudPanel contract ----

# Opening the tab discards any unconfirmed point allocation; a plain refresh()
# (e.g. after confirming) keeps pending points and just redraws.
func on_tab_opened() -> void:
	_reset_pending_allocations()
	refresh()

func get_default_focus_target() -> Control:
	var stat_order: Array[String] = [
		"attack",
		"magic",
		"defense",
		"resist",
	]
	for stat: String in stat_order:
		var button: Button = _up_buttons[stat]
		if not button.disabled and button.is_visible_in_tree():
			return button
	return null

func refresh() -> void:
	var hero := GameState.leader
	if hero == null:
		return
	if _pending_total() > hero.skill_points:
		_reset_pending_allocations()
	_available_points = hero.skill_points - _pending_total()

	_refresh_identity()
	_refresh_bars()
	_refresh_stats()
	_refresh_effects(hero)

# ---- Refresh helpers ----

func _refresh_identity() -> void:
	var hero := GameState.leader
	name_label.text = hero.name
	name_label.add_theme_color_override("font_color", HudStyle.COLOR_HEADER)
	class_label.text = hero.get_class_name()
	class_label.add_theme_color_override("font_color", HudStyle.COLOR_SUBTEXT)
	level_label.text = "Level %d" % hero.level
	level_label.add_theme_color_override("font_color", HudStyle.COLOR_HEADER)
	skill_label.text = "Skill Points: %d" % _available_points
	skill_label.add_theme_color_override("font_color", HudStyle.COLOR_GOLD)

func _refresh_bars() -> void:
	var hero := GameState.leader
	_refresh_bar(hp_bar, hp_label, hero.current_hp, hero.max_hp, "%d / %d HP", HudBarStyle.hp_color(hero.current_hp, hero.max_hp))
	_refresh_bar(nrg_bar, nrg_label, hero.current_nrg, hero.max_nrg, "%d / %d NRG", HudBarStyle.COLOR_NRG)
	_refresh_bar(xp_bar, xp_label, hero.experience, hero.level * Hero.LEVEL_UP_MULT, "%d / %d XP", HudBarStyle.COLOR_XP)

func _refresh_bar(bar: ProgressBar, label: Label, value: int, max_val: int, fmt: String, color: Color) -> void:
	bar.max_value = max(max_val, 1)
	bar.value = value
	label.text = fmt % [value, max_val]
	HudBarStyle.apply(bar, color)

func _refresh_stats() -> void:
	var hero := GameState.leader
	var no_points := _available_points <= 0

	_refresh_stat_label("attack", "Attack", hero.attack)
	_refresh_stat_label("magic", "Magic", hero.magic)
	_refresh_stat_label("defense", "Defense", hero.defense)
	_refresh_stat_label("resist", "Resist", hero.resist)

	for stat in _up_buttons:
		_up_buttons[stat].disabled = no_points
		_down_buttons[stat].disabled = _temp_allocations[stat] <= 0

	gold_label.text = "Gold: %d" % GameState.party.inventory.gold
	gold_label.add_theme_color_override("font_color", HudStyle.COLOR_GOLD)

	confirm_button.visible = _pending_total() > 0

func _refresh_stat_label(stat: String, prefix: String, base_val: int) -> void:
	var bonus: int = _temp_allocations[stat]
	var lbl: Label = _stat_labels[stat]
	if bonus > 0:
		lbl.text = "%s: %d (+%d)" % [prefix, base_val, bonus]
		lbl.add_theme_color_override("font_color", COLOR_BUFFED)
	else:
		lbl.text = "%s: %d" % [prefix, base_val]
		lbl.remove_theme_color_override("font_color")

func _refresh_effects(hero: Hero) -> void:
	clear_children(effects_container)

	var effects: Array[EffectView] = EffectManager.get_active_effects(hero)
	if effects.is_empty():
		effects_container.add_child(HudStyle.label("No active effects", HudStyle.COLOR_SUBTEXT, 11))
		return

	effects_container.add_child(HudStyle.label("Active Effects:", HudStyle.COLOR_HEADER))
	for effect: EffectView in effects:
		effects_container.add_child(HudStyle.label("  • %s" % effect.tooltip_text, HudStyle.COLOR_SUBTEXT, 11))

# ---- Point allocation ----

func _pending_total() -> int:
	var total := 0
	for stat: String in _temp_allocations:
		total += _temp_allocations[stat]
	return total

func _reset_pending_allocations() -> void:
	for stat: String in _temp_allocations:
		_temp_allocations[stat] = 0

func _on_increase(stat: String) -> void:
	if _available_points <= 0:
		return
	_temp_allocations[stat] += 1
	_available_points -= 1
	skill_label.text = "Skill Points: %d" % _available_points
	_refresh_stats()

func _on_decrease(stat: String) -> void:
	if _temp_allocations[stat] <= 0:
		return
	_temp_allocations[stat] -= 1
	_available_points += 1
	skill_label.text = "Skill Points: %d" % _available_points
	_refresh_stats()

func _on_confirm_pressed() -> void:
	var hero := GameState.leader
	for stat in _temp_allocations:
		var increase: int = _temp_allocations[stat]
		if increase <= 0:
			continue
		match stat:
			"attack": hero.attack += increase
			"magic": hero.magic += increase
			"defense": hero.defense += increase
			"resist": hero.resist += increase
	hero.skill_points = _available_points
	_reset_pending_allocations()
	refresh()
