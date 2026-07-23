extends RefCounted
class_name QuestObjectiveFactory

static func from_save_data(data: Dictionary) -> QuestObjective:
	var objective_type := str(data.get("type", "kill"))
	var objective: QuestObjective = null
	match objective_type:
		"kill":
			objective = KillQuestObjective.new()
		_:
			push_warning("QuestObjectiveFactory: unsupported objective type '%s'" % objective_type)
			objective = QuestObjective.new()
	objective.load_save_data(data)
	return objective
