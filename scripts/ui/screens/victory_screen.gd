extends Control
class_name VictoryScreen

@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var hero_info_label: Label = $PanelContainer/VBoxContainer/HeroInfoLabel
@onready var main_menu_button: Button = $PanelContainer/VBoxContainer/MainMenuButton

func _ready() -> void:
	var hero := GameState.hero
	if hero:
		hero_info_label.text = "%s\nLevel %d %s\n\nAttack: %d  Magic: %d\nDefense: %d  Resist: %d\nGold: %d" % [
			hero.name,
			hero.level,
			hero.get_class_name(),
			hero.attack,
			hero.magic,
			hero.defense,
			hero.resist,
			hero.inventory.gold,
		]
	main_menu_button.grab_focus.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return

	if event.is_action_pressed(&"ui_cancel"):
		_return_to_main_menu()
		get_viewport().set_input_as_handled()

func _on_main_menu_button_pressed() -> void:
	_return_to_main_menu()

func _return_to_main_menu() -> void:
	ScreenManager.go_to_screen(ScreenManager.ScreenName.MAIN_MENU)
