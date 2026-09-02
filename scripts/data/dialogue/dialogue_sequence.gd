extends Resource
class_name DialogueSequence

@export var sequence_id: StringName = &""
@export var quest_id: int = -1
@export var priority: int = 0
@export var start_entry_id: StringName = &""
@export var entries: Array[DialogueEntry] = []
@export var state_entries: Dictionary[StringName, StringName] = {}
# state entries is ordered state, DialogueEntry name

func get_start_entry_id(context: Dictionary[StringName, Variant]) -> StringName:
	if quest_id >= 0:
		var quest_state: StringName = context.get(&"quest_state", &"unavailable")
		return state_entries.get(quest_state, &"")
	return start_entry_id

func has_state(quest_state: QuestManager.LifecycleState) -> bool:
	match quest_state:
		QuestManager.LifecycleState.OFFERED:
			return state_entries.has("offered")
		QuestManager.LifecycleState.ACTIVE:
			return state_entries.has("active")
		QuestManager.LifecycleState.READY:
			return state_entries.has("ready")
		QuestManager.LifecycleState.COMPLETED:
			return state_entries.has("completed")
	return false
