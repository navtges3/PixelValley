extends Resource
class_name QuestManager

@export var locked_quests: Array[Quest] = []
@export var available_quests: Array[Quest] = []
@export var completed_quests: Array[Quest] = []

func _init() -> void:
	connect_quests()

func connect_quests() -> void:
	for quest in available_quests:
		quest.quest_completed.connect(Callable(self, "_on_quest_completed"))

func add_available_quest(quest: Quest) -> void:
	if quest not in available_quests and quest not in completed_quests:
		available_quests.append(quest)
		quest.quest_completed.connect(Callable(self, "_on_quest_completed"))

func _on_quest_completed(quest: Quest) -> void:
	if quest in available_quests:
		available_quests.erase(quest)
		completed_quests.append(quest)
		if not quest.next_quests.is_empty():
			# Iterate over a copy to avoid skipping elements when erasing
			for locked_quest in locked_quests.duplicate():
				if quest.next_quests.has(locked_quest.id):
					locked_quests.erase(locked_quest)
					add_available_quest(locked_quest)

func get_save_data() -> Dictionary:
	return {
		"locked_quests": locked_quests.map(func(q: Quest): return q.get_save_data()),
		"available_quests": available_quests.map(func(q: Quest): return q.get_save_data()),
		"completed_quests": completed_quests.map(func(q: Quest): return q.get_save_data()),
	}

static func load_from_data(data: Dictionary) -> QuestManager:
	var manager := QuestManager.new()
	for locked_data in data.get("locked_quests", []):
		var quest = Quest.load_from_data(locked_data)
		manager.locked_quests.append(quest)
	for available_data in data.get("available_quests", []):
		var quest = Quest.load_from_data(available_data)
		manager.available_quests.append(quest)
	for completed_data in data.get("completed_quests", []):
		var quest = Quest.load_from_data(completed_data)
		manager.completed_quests.append(quest)
	manager.connect_quests()
	return manager
