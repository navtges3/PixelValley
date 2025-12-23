extends Node

var current_screen: Node = null

enum ScreenName {
	MAIN_MENU,
	NEW_GAME,
	VILLAGE,
	INN,
	SHOP,
	ARMORY,
	TRAINING,
	BATTLE,
	QUEST,
	QUEST_FINISHED,
	DEFEAT,
	VICTORY,
}

var SCENE_PATHS := {
	ScreenName.MAIN_MENU: "res://scenes/ui/screens/main_menu_screen.tscn",
	ScreenName.NEW_GAME: "res://scenes/ui/screens/new_game_screen.tscn",
	ScreenName.VILLAGE: "res://scenes/ui/screens/village_screen.tscn",
	ScreenName.INN: "res://scenes/ui/screens/inn_screen.tscn",
	ScreenName.SHOP: "res://scenes/ui/screens/shop_screen.tscn",
	ScreenName.ARMORY: "res://scenes/ui/screens/armory_screen.tscn",
	ScreenName.TRAINING: "res://scenes/ui/screens/training_screen.tscn",
	ScreenName.BATTLE: "res://scenes/ui/screens/battle_screen.tscn",
	ScreenName.QUEST: "res://scenes/ui/screens/quest_screen.tscn",
	ScreenName.QUEST_FINISHED: "res://scenes/ui/screens/quest_finished_screen.tscn",
	ScreenName.DEFEAT: "res://scenes/ui/screens/defeat_screen.tscn",
	ScreenName.VICTORY: "res://scenes/ui/screens/victory_screen.tscn",
}

func go_to_screen(screen_name: ScreenName) -> void:
	if SCENE_PATHS.has(screen_name):
		call_deferred("_change_scene", SCENE_PATHS[screen_name])
	else:
		push_error("Screen not found: %s" % screen_name)

func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
