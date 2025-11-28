extends Control

@onready var hero = GameState.hero
@onready var skill_points_label: Label = $MarginContainer/VBoxContainer/SkillPointsLabel

@onready var stat_labels = {
	"attack": $MarginContainer/VBoxContainer/AttackBox/Label,
	"magic": $MarginContainer/VBoxContainer/MagicBox/Label,
	"defense": $MarginContainer/VBoxContainer/DefenseBox/Label,
	"resistance": $MarginContainer/VBoxContainer/ResistanceBox/Label,
}

@onready var plus_buttons = {
	"attack": $MarginContainer/VBoxContainer/AttackBox/Plus,
	"magic": $MarginContainer/VBoxContainer/MagicBox/Plus,
	"defense": $MarginContainer/VBoxContainer/DefenseBox/Plus,
	"resistance": $MarginContainer/VBoxContainer/ResistanceBox/Plus,
}

@onready var minus_buttons = {
	"attack": $MarginContainer/VBoxContainer/AttackBox/Minus,
	"magic": $MarginContainer/VBoxContainer/MagicBox/Minus,
	"defense": $MarginContainer/VBoxContainer/DefenseBox/Minus,
	"resistance": $MarginContainer/VBoxContainer/ResistanceBox/Minus,
}

@onready var back_button: Button = $MarginContainer/VBoxContainer/NavigationBox/BackButton
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/NavigationBox/ConfirmButton

var temp_allocations = {
	"attack": 0,
	"magic": 0,
	"defense": 0,
	"resistance": 0
}
var available_points = 0

func _ready() -> void:
	available_points = hero.skill_points
	for stat in plus_buttons.keys():
		plus_buttons[stat].pressed.connect(_on_increase.bind(stat))
		minus_buttons[stat].pressed.connect(_on_decrease.bind(stat))
	confirm_button.pressed.connect(_on_confirm)
	back_button.pressed.connect(_on_back)
	update_ui()

func _on_increase(stat: String) -> void:
	if available_points > 0:
		temp_allocations[stat] += 1
		available_points -= 1
		update_ui()

func _on_decrease(stat: String) -> void:
	if temp_allocations[stat] > 0:
		temp_allocations[stat] -= 1
		available_points += 1
		update_ui()

func _on_confirm() -> void:
	for stat in temp_allocations.keys():
		var increase = temp_allocations[stat]
		if increase > 0:
			hero.stat_block.set_stat(stat, hero.stat_block.get_stat(stat) + increase)
	hero.skill_points = available_points
	ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE)

func _on_back() -> void:
	ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE)

func update_ui() -> void:
	skill_points_label.text = "Unspent Skill Points: %d" % available_points
	var no_points_left = available_points <= 0

	for stat in stat_labels.keys():
		var base_val = hero.stat_block.get_stat(stat)
		var bonus = temp_allocations[stat]
		if bonus > 0:
			stat_labels[stat].text = "%s: %d (+%d)" % [stat.capitalize(), base_val, bonus]
		else:
			stat_labels[stat].text = "%s: %d" % [stat.capitalize(), base_val]

		plus_buttons[stat].disabled = no_points_left
		minus_buttons[stat].disabled = bonus <= 0
