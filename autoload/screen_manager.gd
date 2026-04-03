extends Node

var _current_screen_name: ScreenName = ScreenName.NONE
var _history: Array[ScreenName] = []

var _is_transitioning := false
var _overlay: ColorRect

enum ScreenName {
	NONE,
	MAIN_MENU, NEW_GAME,
	VILLAGE,
	INN, SHOP, ARMORY, TRAINING, QUEST,
	OVERWORLD,
	FOREST, WAR_CAMP, CAVE,
	BATTLE,
	VICTORY,
	TEST,
}

var SCENE_PATHS := {
	ScreenName.MAIN_MENU: "res://scenes/ui/screens/main_menu_screen.tscn",
	ScreenName.NEW_GAME: "res://scenes/ui/screens/new_game_screen.tscn",
	ScreenName.VILLAGE: "res://scenes/world/locations/village.tscn",
	ScreenName.INN: "res://scenes/ui/screens/inn_screen.tscn",
	ScreenName.SHOP: "res://scenes/ui/screens/shop_screen.tscn",
	ScreenName.ARMORY: "res://scenes/ui/screens/armory_screen.tscn",
	ScreenName.TRAINING: "res://scenes/ui/screens/training_screen.tscn",
	ScreenName.OVERWORLD: "res://scenes/world/locations/overworld.tscn",
	ScreenName.FOREST: "res://scenes/world/locations/forest.tscn",
	ScreenName.WAR_CAMP: "res://scenes/world/locations/war_camp.tscn",
	ScreenName.CAVE: "res://scenes/world/locations/cave.tscn",
	ScreenName.BATTLE: "res://scenes/ui/screens/battle_screen.tscn",
	ScreenName.QUEST: "res://scenes/ui/screens/quest_screen.tscn",
	ScreenName.VICTORY: "res://scenes/ui/screens/victory_screen.tscn",
	ScreenName.TEST: "res://scenes/test/battle_tester.tscn",
}

func _ready() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 1)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.modulate = Color(1, 1, 1, 0)

func _fade(target_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", target_alpha, 0.4)\
		.set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func go_to_screen(screen_name: ScreenName, entrance_id: String = "", data = null) -> void:
	if _is_transitioning:
		return
	if not SCENE_PATHS.has(screen_name):
		push_error("Screen not found: %s" % screen_name)
		return
	if _current_screen_name != ScreenName.NONE:
		_history.append(_current_screen_name)
	_current_screen_name = screen_name
	_change_scene.call_deferred(SCENE_PATHS[screen_name], entrance_id, data)

func go_back(entrance_id: String = "", data = null) -> void:
	if _history.is_empty():
		return
	var previous: ScreenName = _history.pop_back()
	_current_screen_name = previous
	_change_scene.call_deferred(SCENE_PATHS[previous], entrance_id, data)

func _change_scene(path: String, entrance_id: String = "", data = null) -> void:
	_is_transitioning = true
	await _fade(1.0)
	
	var scene = load(path).instantiate()
	get_tree().current_scene.free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	if data != null and scene.has_method("setup"):
		scene.setup(data)
	if entrance_id != "" and scene.has_method("place_player_at_entrance"):
		print("Placing player at entrance: %s" % entrance_id)
		scene.place_player_at_entrance(entrance_id)
	
	await get_tree().process_frame
	await _fade(0.0)
	_is_transitioning = false
