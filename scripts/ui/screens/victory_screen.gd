extends Control
class_name VictoryScreen

@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var hero_info_label: Label = $PanelContainer/VBoxContainer/HeroInfoLabel

func _ready() -> void:
	var hero := GameState.hero
	if hero:
		hero_info_label.text = "%s\nLevel %d %s\n\nAttack: %d  Magic: %d\nDefense: %d  Resistance: %d\nGold: %d" % [
			hero.name,
			hero.level,
			hero.get_class_name(),
			hero.attack,
			hero.magic,
			hero.defense,
			hero.resistance,
			hero.inventory.gold
		]

func _on_main_menu_button_pressed() -> void:
	ScreenManager.go_to_screen(ScreenManager.ScreenName.MAIN_MENU)
