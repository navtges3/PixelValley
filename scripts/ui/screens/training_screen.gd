extends Control

@onready var hero = GameState.hero
@onready var skill_points_label: Label = $PanelContainer/VBoxContainer/SkillPointsLabel

@onready var stat_labels = {
	"attack": $PanelContainer/VBoxContainer/AttackBox/Label,
	"magic": $PanelContainer/VBoxContainer/MagicBox/Label,
	"defense": $PanelContainer/VBoxContainer/DefenseBox/Label,
	"resistance": $PanelContainer/VBoxContainer/ResistanceBox/Label,
}

@onready var plus_buttons = {
	"attack": $PanelContainer/VBoxContainer/AttackBox/Plus,
	"magic": $PanelContainer/VBoxContainer/MagicBox/Plus,
	"defense": $PanelContainer/VBoxContainer/DefenseBox/Plus,
	"resistance": $PanelContainer/VBoxContainer/ResistanceBox/Plus,
}

@onready var minus_buttons = {
	"attack": $PanelContainer/VBoxContainer/AttackBox/Minus,
	"magic": $PanelContainer/VBoxContainer/MagicBox/Minus,
	"defense": $PanelContainer/VBoxContainer/DefenseBox/Minus,
	"resistance": $PanelContainer/VBoxContainer/ResistanceBox/Minus,
}

@onready var confirm_button: Button = $PanelContainer/VBoxContainer/NavigationBox/ConfirmButton

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
	update_ui()

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

func _on_back_button_pressed() -> void:
	ScreenManager.go_back()

func _on_confirm_button_pressed() -> void:
	for stat in temp_allocations.keys():
		var increase = temp_allocations[stat]
		if increase > 0:
			hero.stat_block.set_stat(stat, hero.stat_block.get_stat(stat) + increase)
	hero.skill_points = available_points
	ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE)
