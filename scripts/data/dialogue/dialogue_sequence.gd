extends Resource
class_name DialogueSequence

@export var sequence_id: StringName = &""
@export var can_cancel: bool = true
@export var quest_id: int = -1
@export var priority: int = 0
@export var start_entry_id: StringName = &""
@export var entries: Array[DialogueEntry] = []
@export var state_entries: Dictionary[StringName, StringName] = {}
# state entries is ordered state, DialogueEntry name

func get_start_entry_id(context: Dictionary[StringName, Variant]) -> StringName:
	if quest_id >= 0:
		var quest_state: StringName = context.get(&"quest_state", &"unavailable")
		return state_entries.get(quest_state, start_entry_id)
	return start_entry_id

func has_state(quest_state: QuestManager.LifecycleState) -> bool:
	var state_key: StringName = NpcQuestDialogueController.STATE_CONTEXT.get(
		quest_state, &"unavailable")
	return state_entries.has(state_key)

func get_entry(entry_id: StringName) -> DialogueEntry:
	for entry: DialogueEntry in entries:
		if entry != null and entry.entry_id == entry_id:
			return entry
	return null
