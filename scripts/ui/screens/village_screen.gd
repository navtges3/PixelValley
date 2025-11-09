extends Control

@onready var pause_button: Button = $UIRoot/PauseButton
@onready var pause_popup: Window = $PausePopup
@onready var quests_button: Button = $UIRoot/VillageActions/QuestsButton
@onready var shop_button: Button = $UIRoot/VillageActions/ShopButton
@onready var training_button: Button = $UIRoot/VillageActions/TrainingButton
@onready var hero_ui: HeroUI = $UIRoot/HeroUI

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	pause_button.pressed.connect(_on_pause_button_pressed)
	quests_button.pressed.connect(_on_quests_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)
	training_button.pressed.connect(_on_training_button_pressed)
	if GameState.hero:
		hero_ui.hero = GameState.hero
	if GameState.village.shop.has_inventory():
		shop_button.disabled = false
	else:
		shop_button.disabled = true

func _on_pause_button_pressed():
	pause_popup.popup_centered()

func _on_quests_button_pressed():
	ScreenManager.go_to_screen("quest")

func _on_shop_button_pressed():
	ScreenManager.go_to_screen("shop")

func _on_training_button_pressed():
	ScreenManager.go_to_screen("training")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not pause_popup.is_visible():
		_on_pause_button_pressed()
