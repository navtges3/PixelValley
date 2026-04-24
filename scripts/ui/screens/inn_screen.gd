extends Control

const LOCATION_ID := "inn"

@onready var rest_button: Button = $PanelContainer/VBoxContainer/RestButton
@onready var inn_name_label: Label = $PanelContainer/VBoxContainer/InnNameLabel

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
	ScreenManager.go_back(LOCATION_ID)
