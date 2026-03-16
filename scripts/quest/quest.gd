class_name Quest
extends Resource

@export var title: String
@export var id: int
@export var description: String
@export var monster_objectives: Array[MonsterRequirement]
@export var reward: Array[QuestReward]
@export var next_quests: Array[int]
var completed: bool = false

signal quest_completed

func get_monster() -> Monster:
	var available_ids := []
	for objective in monster_objectives:
		if objective.current_amount < objective.target_amount:
			available_ids.append(objective.monster_id)
	if available_ids.size() == 0:
		return null
	var monster_id = available_ids[randi() % available_ids.size()]
	return MonsterLoader.new_monster(monster_id)

func get_monster_count() -> int:
	var count := 0
	for objective in monster_objectives:
		count += objective.target_amount
	return count

func get_slain_count() -> int:
	var count := 0
	for objective in monster_objectives:
		count += objective.current_amount
	return count

func slay_monster(monster_id: MonsterLoader.MonsterID) -> bool:
	for objective in monster_objectives:
		if objective.monster_id == monster_id:
			objective.current_amount += 1
	return is_complete()

func is_complete() -> bool:
	for objective in monster_objectives:
		if objective.current_amount < objective.target_amount:
			return false
	if not completed:
		completed = true
		emit_signal("quest_completed", self)
	return true
