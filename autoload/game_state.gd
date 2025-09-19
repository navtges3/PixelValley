extends Node

const SAVE_DIR := "user://saves"
const DEFAULT_VILLAGE = preload("res://resources/villlages/default_village.tres")

var hero: Hero = null
var village: Village = null
var current_quest: Quest = null
var quest_manager: QuestManager = null
var save_slot: int = 1

func start_new_game(hero_inst: Hero) -> void:
	hero = hero_inst
	village = DEFAULT_VILLAGE.duplicate()
	quest_manager = QuestManager.new()
	quest_manager.new_game()
	quest_manager.connect_quests()
	SaveManager.save_game()
