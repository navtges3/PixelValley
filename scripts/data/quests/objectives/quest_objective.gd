extends Resource
class_name QuestObjective

var _raw_save_data: Dictionary = {}

func apply_event(_event: GameplayEvent) -> bool:
	return false

func is_complete() -> bool:
	return false

func get_progress_text() -> String:
	if _raw_save_data.is_empty():
		return ""
	return "Unsupported objective (%s)" % get_objective_type()

func reset_progress() -> void:
	pass

func get_save_data() -> Dictionary:
	if not _raw_save_data.is_empty():
		return _raw_save_data.duplicate(true)
	return {
		"type": get_objective_type(),
	}

func load_save_data(data: Dictionary) -> void:
	_raw_save_data = data.duplicate(true)

func get_objective_type() -> String:
	if not _raw_save_data.is_empty():
		return str(_raw_save_data.get("type", "base"))
	return "base"

func get_activation_location_ids() -> Array[String]:
	return []
