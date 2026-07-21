extends Resource
class_name QuestObjective

func apply_event(_event: GameplayEvent) -> bool:
	return false

func is_complete() -> bool:
	return false

func get_progress_text() -> String:
	return ""

func reset_progress() -> void:
	pass

func get_save_data() -> Dictionary:
	return {
		"type": get_objective_type(),
	}

func load_save_data(_data: Dictionary) -> void:
	pass

func get_objective_type() -> String:
	return "base"

func get_activation_location_ids() -> Array[String]:
	return []
