extends Control

@onready var pause_window: Window = $PauseWindow
@onready var shop_button: Button = $UIRoot/VillageActions/ShopButton

func _ready() -> void:	
	if GameState.village.shop.has_inventory():
		shop_button.disabled = false
	else:
		shop_button.disabled = true

func _on_pause_button_pressed():
	pause_window.popup_centered()

func _on_inn_button_pressed():
	ScreenManager.go_to_screen(ScreenManager.ScreenName.INN)

func _on_shop_button_pressed():
	ScreenManager.go_to_screen(ScreenManager.ScreenName.SHOP)

func _on_armory_button_pressed():
	ScreenManager.go_to_screen(ScreenManager.ScreenName.ARMORY)

func _on_training_button_pressed():
	ScreenManager.go_to_screen(ScreenManager.ScreenName.TRAINING)

func _on_quests_button_pressed():
	ScreenManager.go_to_screen(ScreenManager.ScreenName.QUEST)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not pause_window.is_visible():
		_on_pause_button_pressed()
