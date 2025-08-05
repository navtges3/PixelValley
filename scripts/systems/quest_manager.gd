extends Resource
class_name QuestManager

@export var active_quests: Array[Quest] = []
@export var completed_quests: Array[Quest] = []

func add_quest(quest: Quest) -> void:
	if quest not in active_quests:
		active_quests.append(quest)
		quest.quest_completed.connect(Callable(self, "_on_quest_completed"))

func _on_quest_completed(quest: Quest) -> void:
	if quest in active_quests:
		active_quests.erase(quest)
		completed_quests.append(quest)

func get_save_data() -> Dictionary:
	return {
		"active_quests": active_quests.map(func(q: Quest): return q.get_save_data()),
		"completed_quests": completed_quests.map(func(q: Quest): return q.get_save_data()),
	}

static func create_from_data(data: Dictionary) -> QuestManager:
	var manager := QuestManager.new()
	for obj_data in data.get("active_quests", []):
		var quest = Quest.load_from_data(obj_data)
		manager.add_quest(quest)
	for comp_data in data.get("completed_quests", []):
		var quest = Quest.load_from_data(comp_data)
		manager.completed_quests.append(quest)
	return manager
