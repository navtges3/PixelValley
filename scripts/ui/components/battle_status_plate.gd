extends VBoxContainer
class_name BattleStatusPlate

const NAME_COLOR := Color.WHITE
const NAME_COLOR_ACTIVE := Color(1.0, 0.85, 0.3)
const NAME_COLOR_DEFEATED := Color(0.6, 0.6, 0.6)

@onready var name_label: Label = $NameLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel

var combatant: Combatant:
	set(value):
		combatant = value
		if is_node_ready():
			refresh()

func _ready() -> void:
	refresh()

func refresh() -> void:
	if combatant == null:
		return
	var hp := combatant.current_hp
	var max_hp := maxi(combatant.max_hp, 1)
	name_label.text = combatant.name
	health_bar.max_value = max_hp
	health_bar.value = hp
	HudBarStyle.apply(health_bar, HudBarStyle.hp_color(hp, max_hp))
	health_label.text = "KO" if hp <= 0 else "%d / %d" %[hp, max_hp]

func set_active(active: bool) -> void:
	name_label.add_theme_color_override("font_color", NAME_COLOR_ACTIVE if active else NAME_COLOR)

func set_defeated() -> void:
	name_label.add_theme_color_override("font_color", NAME_COLOR_DEFEATED)
	refresh()
