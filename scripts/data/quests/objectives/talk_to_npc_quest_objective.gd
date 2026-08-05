extends QuestObjective
class_name TalkToNpcQuestObjective

@export var target_npc_id: StringName = &""
@export var completed: bool = false

func apply_event(event: GameplayEvent) -> bool:
	if completed or not event is NpcInteractedEvent:
		return false
	var interaction := event as NpcInteractedEvent
	if interaction.npc_id != target_npc_id:
		return false
	completed = true
	return true

func is_complete() -> bool:
	return completed

func get_progress_text() -> String:
	return "Talk to %s: %s" % [
		String(target_npc_id).replace("_", " ").capitalize(),
		"Complete" if completed else "Incomplete"
	]

func reset_progress() -> void:
	completed = false

func get_save_data() -> Dictionary:
	return {
		"type": get_objective_type(),
		"target_npc_id": String(target_npc_id),
		"completed": completed,
	}

func load_save_data(data: Dictionary) -> void:
	target_npc_id = StringName(str(data.get("target_npc_id", "")))
	completed = bool(data.get("completed", false))

func get_objective_type() -> String:
	return "talk_to_npc"
