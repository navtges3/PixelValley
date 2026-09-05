extends Node

const Game = preload("res://scripts/game/game.gd")

var _current_screen_name: ScreenName = ScreenName.NONE
var _history: Array[ScreenName] = []

var _is_transitioning := false
var _overlay: ColorRect
var _world_hud: CanvasLayer = null

const WORLD_HUD = preload("res://scenes/ui/hud/world_hud.tscn")

enum ScreenName {
	NONE,
	MAIN_MENU, NEW_GAME,
	VILLAGE,
	INN, POTION_SHOP, WEAPON_SHOP,
	VALLEY,
	FOREST, WAR_CAMP, CAVE,
	BATTLE,
	VICTORY,
}

const WORLD_SCREENS: Array = [
	ScreenName.VALLEY,
	ScreenName.VILLAGE,
	ScreenName.INN,
	ScreenName.WEAPON_SHOP,
	ScreenName.POTION_SHOP,
	ScreenName.FOREST,
	ScreenName.WAR_CAMP,
	ScreenName.CAVE,
]

const SCENE_PATHS := {
	ScreenName.MAIN_MENU: "res://scenes/ui/screens/main_menu_screen.tscn",
	ScreenName.NEW_GAME: "res://scenes/ui/screens/new_game_screen.tscn",
	ScreenName.VILLAGE: "res://scenes/world/locations/village.tscn",
	ScreenName.INN: "res://scenes/world/buildings/interior/inn_interior.tscn",
	ScreenName.POTION_SHOP: "res://scenes/world/buildings/interior/potion_shop_interior.tscn",
	ScreenName.WEAPON_SHOP: "res://scenes/world/buildings/interior/weapon_shop_interior.tscn",
	ScreenName.VALLEY: "res://scenes/world/locations/valley.tscn",
	ScreenName.FOREST: "res://scenes/world/locations/forest.tscn",
	ScreenName.WAR_CAMP: "res://scenes/world/locations/war_camp.tscn",
	ScreenName.CAVE: "res://scenes/world/locations/cave.tscn",
	ScreenName.BATTLE: "res://scenes/ui/screens/battle_screen.tscn",
	ScreenName.VICTORY: "res://scenes/ui/screens/victory_screen.tscn",
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

	_world_hud = WORLD_HUD.instantiate()
	add_child(_world_hud)
	_world_hud.hide()

func get_world_hud() -> CanvasLayer:
	return _world_hud

func get_current_screen_name() -> ScreenName:
	return _current_screen_name

func is_transitioning() -> bool:
	return _is_transitioning

func _fade(target_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", target_alpha, 0.4)\
		.set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func go_to_screen(screen_name: ScreenName, entrance_id: String = "", data: Variant = null) -> void:
	if _is_transitioning:
		return
	if not SCENE_PATHS.has(screen_name):
		push_error("Screen not found: %s" % screen_name)
		return
	_is_transitioning = true
	if screen_name == ScreenName.MAIN_MENU:
		_history.clear()
	elif _current_screen_name != ScreenName.NONE:
		_history.append(_current_screen_name)
	_current_screen_name = screen_name
	_change_scene.call_deferred(SCENE_PATHS[screen_name], entrance_id, data)

func go_back(entrance_id: String = "", data: Variant = null) -> void:
	if _is_transitioning:
		return
	if _history.is_empty():
		return
	_is_transitioning = true
	var previous: ScreenName = _history.pop_back()
	_current_screen_name = previous
	_change_scene.call_deferred(SCENE_PATHS[previous], entrance_id, data)

func _change_scene(path: String, entrance_id: String = "", data: Variant = null) -> void:
	_is_transitioning = true
	var world_hud := _world_hud as WorldHUD
	if world_hud != null:
		world_hud.abort_dialogue()
	await _fade(1.0)
	if _world_hud != null:
		_world_hud.hide()

	var game := Game.get_instance()
	if game == null:
		_fallback_change_scene(path, entrance_id, data)
		return

	var player := Game.get_player()
	var old_location := Game.get_current_location()

	# Ensure the persistent player is safely preserved under Game before freeing old location
	if player != null and player.get_parent() != null and player.get_parent() != game:
		player.reparent(game, false)

	# Clean up previous location
	if old_location != null:
		if old_location.get_parent() != null:
			old_location.get_parent().remove_child(old_location)
		old_location.queue_free()
		Game.set_current_location(null)

	# Clean up previous UI screen
	var old_ui := Game.get_current_ui()
	if old_ui != null:
		if old_ui.get_parent() != null:
			old_ui.get_parent().remove_child(old_ui)
		old_ui.queue_free()
		Game.set_current_ui(null)

	var scene_res := load(path)
	if scene_res == null:
		push_error("Failed to load scene at path: %s" % path)
		_is_transitioning = false
		return

	var scene_instance = scene_res.instantiate()

	if scene_instance is BaseLocation:
		var new_location := scene_instance as BaseLocation
		Game.get_world().add_child(new_location)
		Game.set_current_location(new_location)
		if player != null:
			new_location.attach_player(player, entrance_id)
			player.refresh_camera_limits()
		if data != null and new_location.has_method("setup"):
			new_location.setup(data)
		if _world_hud != null:
			_world_hud.show_all()
	else:
		if player != null:
			player.disable_player()
		var screens_container := Game.get_screens_container()
		if screens_container != null:
			screens_container.add_child(scene_instance)
		else:
			game.add_child(scene_instance)
		Game.set_current_ui(scene_instance as Control)
		if data != null and scene_instance.has_method("setup"):
			scene_instance.setup(data)
		if _world_hud != null:
			_world_hud.hide_all()

	await get_tree().process_frame
	await _fade(0.0)
	_is_transitioning = false

func _fallback_change_scene(path: String, entrance_id: String = "", data: Variant = null) -> void:
	var scene = load(path).instantiate()
	if get_tree().current_scene != null:
		get_tree().current_scene.free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	if data != null and scene.has_method("setup"):
		scene.setup(data)
	if entrance_id != "" and scene.has_method("place_player_at_entrance"):
		scene.place_player_at_entrance(entrance_id)
	if _current_screen_name in WORLD_SCREENS:
		if _world_hud != null:
			_world_hud.show_all()
	else:
		if _world_hud != null:
			_world_hud.hide_all()
	await get_tree().process_frame
	await _fade(0.0)
	_is_transitioning = false
