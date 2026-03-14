extends Control

@onready var inn_name_label: Label = $HBoxContainer/VBoxContainer/InnNameLabel
@onready var rest_button: Button = $HBoxContainer/VBoxContainer/RestButton
@onready var leave_button: Button = $HBoxContainer/VBoxContainer/LeaveButton

var hero: Hero
var inn: Inn

func _ready() -> void:
	hero = GameState.hero
	inn = GameState.village.inn
	inn_name_label.text = inn.name
	if hero.inventory.gold < inn.rest_cost:
		rest_button.disabled = true

func _on_rest_button_pressed() -> void:
	if hero.inventory.gold >= inn.rest_cost:
		hero.inventory.gold -= inn.rest_cost
		hero.rest()

func _on_leave_button_pressed() -> void:
	ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE)
