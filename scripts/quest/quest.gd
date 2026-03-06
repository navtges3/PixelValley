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
	var candidates := []
	for objective in monster_objectives:
		if objective.current_amount < objective.target_amount:
			candidates.append(objective.monster)
	if candidates.size() == 0:
		return null
	return candidates[randi() % candidates.size()]

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

func slay_monster(monster_name: String) -> bool:
	for objective in monster_objectives:
		if objective.monster.name == monster_name:
			objective.current_amount += 1
	return is_complete()

func is_complete() -> bool:
	for objective in monster_objectives:
		if objective.current_amount < objective.target_amount:
			return false
	complete_quest()
	return completed

func complete_quest() -> void:
	if not completed:
		completed = true
		emit_signal("quest_completed", self)
