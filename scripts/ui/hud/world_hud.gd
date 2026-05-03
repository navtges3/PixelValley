extends CanvasLayer
class_name WorldHUD

@onready var game_hud: GameHUD = $GameHud

func hide_all() -> void:
	hide()
	game_hud.hide_hud()
	for child in get_children():
		if child is Control:
			child.visible = false

func show_all() -> void:
	show()
	for child in get_children():
		if child is Control:
			child.visible = true

func open_game_hud(tab: GameHUD.Tab = GameHUD.Tab.STATS) -> void:
	game_hud.show_hud(tab)

func close_game_hud() -> void:
	game_hud.hide_hud()
