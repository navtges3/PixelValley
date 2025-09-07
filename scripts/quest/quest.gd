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

func slay_monster(monster_name: String) -> bool:
	for objective in monster_objectives:
		if objective.monster.name == monster_name:
			objective.current_amount += 1
	return is_complete()

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

func complete_quest() -> void:
	completed = true
	emit_signal("quest_completed", self)

func is_complete() -> bool:
	for objective in monster_objectives:
		if objective.current_amount < objective.target_amount:
			return false
	completed = true
	emit_signal("quest_completed", self)
	return completed

func get_save_data() -> Dictionary:
	return {
		"title": title,
		"description": description,
		"monster_objectives": monster_objectives.map(func(obj: MonsterRequirement): return obj.get_save_data()),
		"reward": reward.map(func(r: QuestReward): return r.get_save_data()),
		"completed": completed,
	}

static func load_from_data(data: Dictionary) -> Quest:
	var quest = Quest.new()
	quest.title = data.get("title", "")
	quest.description = data.get("description", "")
	for obj_data in data.get("monster_objectives", []):
		var obj = MonsterRequirement.load_from_data(obj_data)
		quest.monster_objectives.append(obj)
	for reward_data in data.get("reward", []):
		var r = QuestReward.load_from_data(reward_data)
		quest.reward.append(r)
	quest.completed = data.get("completed", false)
	return quest
