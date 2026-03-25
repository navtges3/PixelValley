extends Node

const SAVE_DIR := "user://saves"
const DEFAULT_VILLAGE = preload("res://resources/villages/default_village.tres")

var hero: Hero = null
var village: Village = null
var current_quest: Quest = null
var quest_manager: QuestManager = null
var unlocked_zones: Array = []

# ---------------------------------------------------------
# GAME START FLOW
# ---------------------------------------------------------
func start_new_game(slot := 1) -> void:
	village = DEFAULT_VILLAGE.duplicate()
	quest_manager = QuestManager.new()
	quest_manager.new_game()
	reset_zone_state()
	SaveManager.new_save(slot)
	print("GameState: New game started in slot %d" % slot)

func reset_state() -> void:
	hero = null
	village = null
	current_quest = null
	quest_manager = null

func unlock_zone(zone_id: String) -> void:
	if zone_id not in unlocked_zones:
		unlocked_zones.append(zone_id)
		SaveManager.save_game()

func is_zone_unlocked(zone_id: String) -> bool:
	return zone_id in unlocked_zones

func reset_zone_state() -> void:
	unlocked_zones.clear()
