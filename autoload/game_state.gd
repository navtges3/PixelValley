extends Node

const SAVE_DIR := "user://saves"
const START_QUEST_MANAGER = preload("res://resources/quests/start_quest_manager.tres")
const DEFAULT_VILLAGE = preload("res://resources/villlages/default_village.tres")

var hero: HeroInstance = null
var village: Village = null
var current_quest: Quest = null
var quest_manager: QuestManager = null
var save_slot: int = 1

func start_new_game(hero_inst: HeroInstance) -> void:
	hero = hero_inst
	village = DEFAULT_VILLAGE.duplicate()
	quest_manager = START_QUEST_MANAGER.duplicate()

func save_game(slot: int = save_slot) -> void:
	var data: Dictionary = {
		"hero": hero.get_save_data(),
		"village": village.get_save_data(),
		"quests": quest_manager.get_save_data(),
	}

	SaveManager.save_game(data, slot)
	save_slot = slot

func load_game(slot: int) -> void:
	var data := SaveManager.load_game(slot)
	if data.is_empty():
		return

	hero = HeroInstance.create_from_data(data.get("hero", {}))
	village = Village.create_from_data(data.get("village", {}))
	quest_manager = QuestManager.create_from_data(data.get("quests", {}))
	if not hero or not village:
		push_error("Failed to load game data. Invalid hero or village.")
	save_slot = slot
