class_name Quest
extends Resource

@export var title: String
@export var id: int
@export var description: String
@export var monster_objectives: Array[MonsterRequirement]
@export var reward: Array[QuestReward]
@export var next_quests: Array[int]
@export var unlocks_locations: Array[String] = []
@export var completed: bool = false

signal quest_completed(quest: Quest)

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

func slay_monster(monster_id: MonsterLoader.MonsterID, location_id: String = "") -> bool:
	for objective in monster_objectives:
		if objective.monster_id != monster_id:
			continue
		if objective.location_id != "" and objective.location_id != location_id:
			continue
		if objective.current_amount < objective.target_amount:
			objective.current_amount += 1
	return check_completion()

func all_objectives_met() -> bool:
	for objective in monster_objectives:
		if objective.current_amount < objective.target_amount:
			return false
	return true

func check_completion() -> bool:
	if not all_objectives_met():
		return false
	if not completed:
		completed = true
		quest_completed.emit(self)
	return true
