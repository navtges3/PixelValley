extends Node
class_name SaveManager

const SAVE_DIR := "user://saves"
const MAX_SLOTS := 3

static func save_game(data: Dictionary, slot: int = 1) -> void:
	var save_path = get_save_path(slot)
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	print("SaveManager: Game saved to slot ", slot)

static func load_game(slot: int) -> Dictionary:
	var save_path = get_save_path(slot)
	if not FileAccess.file_exists(save_path):
		push_error("SaveManager: Save file not found at slot %d" % slot)
		return {}
	var file = FileAccess.open(save_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("SaveManager: Invalid save data format in slot %d" % slot)
		return {}
	return data

static func load_save_slot(slot: int) -> String:
	var save_path = get_save_path(slot)
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		var data = JSON.parse_string(content)
		var hero_data = data.get("hero", {})
		if not hero_data:
			push_error("No Hero found in save file.")
			return "Error"
		var hero_name = hero_data.get("hero_name", "Unknown")
		var hero_level = hero_data.get("level", 1)

		return "%s - Lvl: %d" % [hero_name, hero_level]
	else:
		return "Empty Slot"

static func delete_save(slot: int) -> void:
	var save_path = get_save_path(slot)
	if FileAccess.file_exists(save_path):
		var err = DirAccess.remove_absolute(save_path)
		if err != OK:
			push_error("SaveManager: Failed to delete save file: %s" % err)
		else:
			print("SaveManager: Save slot %d deleted successfully." % slot)

static func get_existing_save_slots(num_slots: int = SaveManager.MAX_SLOTS) -> Array:
	var available_slots := []
	for slot in range(1, num_slots + 1):
		var save_path = get_save_path(slot)
		if FileAccess.file_exists(save_path):
			available_slots.append(slot)
	return available_slots

static func has_any_save(num_slots: int = SaveManager.MAX_SLOTS) -> bool:
	return not get_existing_save_slots(num_slots).is_empty()

static func get_save_path(slot: int) -> String:
	var saves_dir = ProjectSettings.globalize_path(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(saves_dir)
	return saves_dir.path_join("save_slot_%d.save" % slot)