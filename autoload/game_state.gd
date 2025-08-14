extends Node

const SAVE_DIR := "user://saves"
const START_QUEST_MANAGER = preload("res://resources/quests/start_quest_manager.tres")
const DEFAULT_VILLAGE = preload("res://resources/villlages/default_village.tres")

var hero: Hero = null
var village: Village = null
var current_quest: Quest = null
var quest_manager: QuestManager = null
var save_slot: int = 1

func start_new_game(hero_inst: Hero) -> void:
	hero = hero_inst
	village = DEFAULT_VILLAGE.duplicate()
	quest_manager = START_QUEST_MANAGER.duplicate()
	SaveManager.save_game()
