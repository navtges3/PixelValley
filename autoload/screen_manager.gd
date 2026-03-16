extends Node

var _current_screen_name: ScreenName = ScreenName.NONE
var _history: Array[ScreenName] = []

enum ScreenName {
	NONE,
	MAIN_MENU,
	NEW_GAME,
	VILLAGE,
	INN,
	SHOP,
	ARMORY,
	TRAINING,
	BATTLE,
	QUEST,
	DEFEAT,
	VICTORY,
	TEST,
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
	ScreenName.DEFEAT: "res://scenes/ui/screens/defeat_screen.tscn",
	ScreenName.VICTORY: "res://scenes/ui/screens/victory_screen.tscn",
	ScreenName.TEST: "res://scenes/test/battle_tester.tscn",
}

func go_to_screen(screen_name: ScreenName, data = null) -> void:
	if SCENE_PATHS.has(screen_name):
		if _current_screen_name != ScreenName.NONE:
			_history.append(_current_screen_name)
		call_deferred("_change_scene", SCENE_PATHS[screen_name], data)
	else:
		push_error("Screen not found: %s" % screen_name)

func go_back() -> void:
	if _history.is_empty():
		return
	var previous: ScreenName = _history.pop_back()
	go_to_screen(previous)

func _change_scene(path: String, data = null) -> void:
	var scene = load(path).instantiate()
	
	if data != null and scene.has_method("setup"):
		scene.setup(data)
	
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
