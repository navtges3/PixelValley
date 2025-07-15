extends Node

var current_screen: Node = null
const SCENE_PATHS := {
	"main_menu": "res://scenes/ui/screens/main_menu_screen.tscn",
	"new_game": "res://scenes/ui/screens/new_game_screen.tscn",
	"load_game": "res://scenes/ui/screens/load_game_screen.tscn",
	"village": "res://scenes/ui/screens/village_screen.tscn",
	"battle": "res://scenes/ui/screens/battle_screen.tscn",
	"quest": "res://scenes/ui/screens/quest_screen.tscn",
	"quest_finished": "res://scenes/ui/screens/quest_finished_screen.tscn",
	"defeat": "res://scenes/ui/screens/defeat_screen.tscn",
}

func go_to_screen(screen_name: String) -> void:
	if SCENE_PATHS.has(screen_name):
		call_deferred("_change_scene", SCENE_PATHS[screen_name])
	else:
		push_error("Screen not found: %s" % screen_name)

func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)