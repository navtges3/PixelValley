extends RefCounted
class_name DialogueConditionEvaluator

func are_met(conditions: Array[DialogueCondition], context: Dictionary[StringName, Variant]) -> bool:
	for condition: DialogueCondition in conditions:
		if condition == null:
			push_warning("Dialogue contains a null condition.")
			return false
		if not is_met(condition, context):
			return false
	return true

func is_met(condition: DialogueCondition, context: Dictionary[StringName, Variant]) -> bool:
	match condition.condition_id:
		&"always":
			return true
		&"context_equals":
			return _context_equals(condition, context)
		_:
			push_warning("Unsupported dialogue condition: %s" % condition.condition_id)
			return false

func _context_equals(condition: DialogueCondition, context: Dictionary[StringName, Variant]) -> bool:
	if (
		not condition.parameters.has(&"key")
		or not condition.parameters.has(&"value")
	):
		return false
	var key_value: Variant = condition.parameters.get(&"key", &"")
	var key := StringName(str(key_value))
	if key.is_empty() or not context.has(key):
		return false
	var expected: Variant = condition.parameters.get(&"value")
	return context[key] == expected
