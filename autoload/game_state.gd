extends Node

const SAVE_DIR := "user://saves"
const DEFAULT_VILLAGE = preload("res://resources/villages/default_village.tres")

var hero: Hero = null
var village: Village = null
var current_quest: Quest = null
var quest_manager: QuestManager = null
var pre_combat_position: Vector2 = Vector2.ZERO

signal monster_killed(monster_id: MonsterLoader.MonsterID, location_id: String)

# --- Game Start Flow ---
func start_new_game(slot := 1) -> void:
	village = DEFAULT_VILLAGE.duplicate()
	quest_manager = QuestManager.new()
	quest_manager.new_game()
	WorldManager.reset()
	SaveManager.new_save(slot)
	print("GameState: New game started in slot %d" % slot)

func reset_state() -> void:
	hero = null
	village = null
	current_quest = null
	quest_manager = null

# --- Player Location ---
var player_location: Dictionary = {
	"scene": ScreenManager.ScreenName.OVERWORLD,
	"entrance_id": ""
}

func set_player_location(scene: ScreenManager.ScreenName, entrance_id: String = "") -> void:
	print("Scene: %s, Entrance: %s" % [scene, entrance_id])
	player_location["scene"] = scene
	player_location["entrance_id"] = entrance_id
