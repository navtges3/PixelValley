extends Resource
class_name QuestManager

const QUEST_LIST := [
	"res://resources/quests/quest_1.tres",
	"res://resources/quests/quest_2.tres",
	"res://resources/quests/quest_3.tres",
	"res://resources/quests/quest_4.tres",
	"res://resources/quests/quest_5.tres",
	"res://resources/quests/quest_6.tres",
	"res://resources/quests/quest_7.tres",
	"res://resources/quests/quest_8.tres",
	"res://resources/quests/quest_9.tres",
	"res://resources/quests/quest_10.tres",
	"res://resources/quests/quest_11.tres",
	"res://resources/quests/quest_12.tres",
	"res://resources/quests/quest_13.tres",
	"res://resources/quests/quest_14.tres",
	"res://resources/quests/quest_15.tres",
	"res://resources/quests/quest_101.tres",
	"res://resources/quests/quest_102.tres"
]

const FIRST_QUEST_ID := 1
const LAST_QUEST_ID := 15

@export var locked_quests: Array[Quest] = []
@export var available_quests: Array[Quest] = []
@export var completed_quests: Array[Quest] = []

func _on_quest_completed(quest: Quest) -> void:
	if quest in available_quests:
		available_quests.erase(quest)
		completed_quests.append(quest)
		for next_id in quest.next_quests:
			unlock_quest_by_id(next_id)
		SaveManager.save_game()

func new_game() -> void:
	locked_quests = []
	available_quests = []
	completed_quests = []
	for quest_res in QUEST_LIST:
		var quest = load(quest_res)
		locked_quests.append(quest)
	if locked_quests.size() > 0:
		unlock_quest_by_id(FIRST_QUEST_ID)

func unlock_quest_by_id(quest_id: int) -> void:
	for locked_quest in locked_quests.duplicate():
		if locked_quest.id == quest_id:
			locked_quests.erase(locked_quest)
			add_available_quest(locked_quest)
			return

func add_available_quest(quest: Quest) -> void:
	if quest not in available_quests and quest not in completed_quests:
		available_quests.append(quest)
		quest.quest_completed.connect(Callable(self, "_on_quest_completed"))

func get_save_data() -> Dictionary:
	return {
		"locked_quests": locked_quests.map(func(q: Quest): return q.get_save_data()),
		"available_quests": available_quests.map(func(q: Quest): return q.get_save_data()),
		"completed_quests": completed_quests.map(func(q: Quest): return q.get_save_data()),
	}

static func load_from_data(data: Dictionary) -> QuestManager:
	var manager := QuestManager.new()
	manager.locked_quests = []
	manager.available_quests = []
	manager.completed_quests = []
	for locked_data in data.get("locked_quests", []):
		var quest = Quest.load_from_data(locked_data)
		manager.locked_quests.append(quest)
	for available_data in data.get("available_quests", []):
		var quest = Quest.load_from_data(available_data)
		quest.quest_completed.connect(Callable(manager, "_on_quest_completed"))
		manager.available_quests.append(quest)
	for completed_data in data.get("completed_quests", []):
		var quest = Quest.load_from_data(completed_data)
		manager.completed_quests.append(quest)
	return manager
