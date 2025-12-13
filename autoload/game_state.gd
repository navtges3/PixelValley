extends Node

const SAVE_DIR := "user://saves"
const DEFAULT_VILLAGE = preload("res://resources/villlages/default_village.tres")

var hero: Hero = null
var village: Village = null
var current_quest: Quest = null
var quest_manager: QuestManager = null
var save_slot: int = 1

# ---------------------------------------------------------
# GAME START FLOW
# ---------------------------------------------------------
func start_new_game(hero_inst: Hero, slot := 1) -> void:
	save_slot = slot
	hero = hero_inst
	village = DEFAULT_VILLAGE.duplicate()
	quest_manager = QuestManager.new()
	quest_manager.new_game()
	SaveManager.save_game()
	print("GameState: New game started in slot %d" % save_slot)

func load_game(slot := 1) -> void:
	save_slot = slot

	if not SaveManager.has_save_data(slot):
		push_error("GameState: No save data found in slot %d" % slot)
		return

	SaveManager.load_game()

	print("GameState: Game loaded from slot %d" % save_slot)

func save_game() -> void:
	SaveManager.save_game()

func reset_state() -> void:
	hero = null
	village = null
	current_quest = null
	quest_manager = null

func get_slot_meta(slot: int) -> Dictionary:
	var path := SaveManager.get_slot_dir(slot).path_join("meta.json")
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data
