extends Node

const SAVE_DIR := "user://saves"

var hero: HeroInstance = null
var village: Village = null
var current_quest: Quest = null
var save_slot: int = 1

func start_new_game(hero_inst: HeroInstance) -> void:
	hero = hero_inst
	village = Village.new()
	QuestDatabase.new_game()

func save_game(slot: int = save_slot) -> void:
	var save_path = get_relative_save_path(slot)
	var file = FileAccess.open(save_path, FileAccess.WRITE)

	var data: Dictionary = {
		"hero": hero.get_save_data(),
		"village": village.get_save_data(),
		"quests": QuestDatabase.get_save_data(),
	}

	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	print("Game saved to slot ", slot)

func load_game(slot: int) -> void:
	var save_path = get_relative_save_path(slot)
	if not FileAccess.file_exists(save_path):
		print("Save file not found")
		return
	var file = FileAccess.open(save_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	hero = HeroInstance.create_from_data(data["hero"])
	if not hero:
		print("Failed to load hero data")
		return
	village = Village.new()
	village.load_from_data(data["village"])
	QuestDatabase.load_from_data(data["quests"])
	save_slot = slot

func delete_save(slot: int) -> void:
	var save_path = get_relative_save_path(slot)
	if FileAccess.file_exists(save_path):
		var err = DirAccess.remove_absolute(save_path)
		if err != OK:
			push_error("Failed to delete save file: %s" % err)
		else:
			print("Save slot %d deleted successfully." % slot)

func has_any_save(max_slots: int = 3) -> bool:
	return not get_available_save_slots(max_slots).is_empty()

func get_available_save_slots(max_slots: int = 3) -> Array:
	var available_slots := []
	for slot in range(1, max_slots + 1):
		var save_path = get_relative_save_path(slot)
		if FileAccess.file_exists(save_path):
			available_slots.append(slot)
	return available_slots

func get_relative_save_path(slot: int) -> String:
	var saves_dir = ProjectSettings.globalize_path(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(saves_dir)
	return saves_dir.path_join("save_slot_%d.save" % slot)