extends QuestObjective
class_name KillQuestObjective

@export var monster_id: MonsterLoader.MonsterID
@export_range(1, 999, 1) var target_amount: int = 1
@export var current_amount: int = 0
@export var location_id: String = ""

func apply_event(_event: GameplayEvent) -> bool:
	if is_complete():
		return false
	if not _event is MonsterKilledEvent:
		return false
	var kill_event := _event as MonsterKilledEvent
	if kill_event.monster_id != monster_id:
		return false
	if not location_id.is_empty() and kill_event.location_id != location_id:
		return false
	current_amount = mini(current_amount + 1, target_amount)
	return true

func is_complete() -> bool:
	return current_amount >= target_amount

func get_progress_text() -> String:
	var monster_name := MonsterLoader.get_monster_name(monster_id)
	var location_hint := ""
	if not location_id.is_empty():
		location_hint = " [%s]" % location_id.replace("_", " ").capitalize()
	return "%s%s: %d/%d" % [
		monster_name,
		location_hint,
		current_amount,
		target_amount,
	]

func reset_progress() -> void:
	current_amount = 0

func get_save_data() -> Dictionary:
	return {
		"type": get_objective_type(),
		"monster_id": monster_id,
		"target_amount": target_amount,
		"current_amount": current_amount,
		"location_id": location_id,
	}

func load_save_data(data: Dictionary) -> void:
	monster_id = data.get("monster_id", MonsterLoader.MonsterID.GOBLIN)
	target_amount = maxi(int(data.get("target_amount", 1)), 1)
	current_amount = clampi(int(data.get("current_amount", 0)), 0, target_amount)
	location_id = str(data.get("location_id", ""))

func get_objective_type() -> String:
	return "kill"

func get_activation_location_ids() -> Array[String]:
	if location_id.is_empty():
		return []
	return [location_id]
