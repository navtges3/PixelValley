extends Control

@onready var pause_button = $CanvasLayer/UIRoot/Pause
@onready var pause_popup = $PausePopup
@onready var quests_button = $CanvasLayer/UIRoot/VillageActions/Quests
@onready var shop_button = $CanvasLayer/UIRoot/VillageActions/Shop
@onready var hero_ui = $CanvasLayer/UIRoot/HeroUI

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	pause_button.pressed.connect(_on_pause_button_pressed)
	quests_button.pressed.connect(_on_quests_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)

	if GameState.hero:
		hero_ui.set_hero_info(GameState.hero)

func _on_pause_button_pressed():
	pause_popup.popup_centered()

func _on_quests_button_pressed():
	ScreenManager.go_to_screen("quest")

func _on_shop_button_pressed():
	ScreenManager.go_to_screen("shop")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not pause_popup.is_visible():
		_on_pause_button_pressed()
