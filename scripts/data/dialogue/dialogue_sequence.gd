extends Resource
class_name DialogueSequence

enum SequenceType {
	QUEST,
	DEFAULT,
	NOT_AVAILABLE,
}

@export var sequence_id: StringName = &""
@export var sequence_type: SequenceType = SequenceType.DEFAULT
@export var can_cancel: bool = true
@export var quest_id: int = -1
@export var priority: int = 0
@export var start_entry_id: StringName = &""
@export var entries: Array[DialogueEntry] = []
@export var state_entries: Dictionary[StringName, StringName] = {}

func get_start_entry_id(context: Dictionary[StringName, Variant]) -> StringName:
	if quest_id >= 0:
		var quest_state: StringName = get_quest_state(context)
		return state_entries.get(quest_state, start_entry_id)
	if context.has(&"main_progression"):
		var progression: StringName = StringName(context[&"main_progression"])
		return state_entries.get(progression, start_entry_id)
	return start_entry_id

func get_quest_state(context: Dictionary[StringName, Variant]) -> StringName:
	if quest_id < 0:
		return &""
	if context.has(&"quest_states") and context[&"quest_states"] is Dictionary:
		var states: Dictionary = context[&"quest_states"]
		if states.has(quest_id):
			return StringName(states[quest_id])
	if context.get(&"quest_id", -1) == quest_id:
		return StringName(context.get(&"quest_state", &"unavailable"))
	return &"unavailable"

func is_eligible(context: Dictionary[StringName, Variant]) -> bool:
	if quest_id >= 0:
		var state := get_quest_state(context)
		return not state.is_empty() and state != &"unavailable" and state_entries.has(state)
	return not start_entry_id.is_empty() or not entries.is_empty()
