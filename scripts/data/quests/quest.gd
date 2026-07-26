extends Resource
class_name Quest

enum Category { MAIN, SIDE }
enum SourceType { AUTOMATIC, QUEST_BOARD, NPC, SCRIPTED_EVENT }

@export var title: String
@export var id: int
@export var description: String
@export_category("Classification")
@export var category: Category = Category.MAIN
@export var source_type: SourceType = SourceType.AUTOMATIC
@export var source_id: String = ""
@export_category("Progression")
@export var objectives: Array[QuestObjective]
@export var reward: Reward = Reward.new()
@export var next_quests: Array[int]
@export var unlocks_locations: Array[String] = []
@export var completed: bool = false
@export var final_quest: bool = false

func apply_event(event: GameplayEvent) -> bool:
	var progress_changed := false
	for objective: QuestObjective in objectives:
		if objective.apply_event(event):
			progress_changed = true
	return progress_changed

func objectives_met() -> bool:
	if objectives.is_empty():
		return false
	for objective: QuestObjective in objectives:
		if not objective.is_complete():
			return false
	return true

func reset_objectives() -> void:
	for objective: QuestObjective in objectives:
		objective.reset_progress()

func get_activation_location_ids() -> Array[String]:
	var location_ids: Array[String] = []
	for objective: QuestObjective in objectives:
		for location_id: String in objective.get_activation_location_ids():
			if location_id not in location_ids:
				location_ids.append(location_id)
	return location_ids
