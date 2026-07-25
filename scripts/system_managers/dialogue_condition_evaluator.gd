extends RefCounted
class_name DialogueConditionEvaluator

func are_met(conditions: Array[DialogueCondition], _context: Dictionary[StringName, Variant]) -> bool:
	for condition: DialogueCondition in conditions:
		if condition.condition_id != &"always":
			push_warning("Unsupported dialogue condition: %s" % condition.condition_id)
			return false
	return true
