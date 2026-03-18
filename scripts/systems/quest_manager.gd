extends Resource
class_name QuestManager

const QUEST_LIST := [
	preload("res://resources/quests/quest_1.tres"),
	preload("res://resources/quests/quest_2.tres"),
	preload("res://resources/quests/quest_3.tres"),
	preload("res://resources/quests/quest_4.tres"),
	preload("res://resources/quests/quest_5.tres"),
	preload("res://resources/quests/quest_6.tres"),
	preload("res://resources/quests/quest_7.tres"),
	preload("res://resources/quests/quest_8.tres"),
	preload("res://resources/quests/quest_9.tres"),
	preload("res://resources/quests/quest_10.tres"),
	preload("res://resources/quests/quest_11.tres"),
	preload("res://resources/quests/quest_12.tres"),
	preload("res://resources/quests/quest_13.tres"),
	preload("res://resources/quests/quest_14.tres"),
	preload("res://resources/quests/quest_15.tres"),
	preload("res://resources/quests/quest_101.tres"),
	preload("res://resources/quests/quest_102.tres")
]


const FIRST_QUEST_ID := 1
const LAST_QUEST_ID := 15

@export var locked_quests: Array[Quest] = []
@export var available_quests: Array[Quest] = []
@export var completed_quests: Array[Quest] = []

func _on_quest_completed(quest: Quest) -> void:
	if quest not in available_quests:
		push_warning("QuestManager: completed quest '%s' was not in available_quests" % quest.title)
		return
	apply_rewards(quest)
	for next_id in quest.next_quests:
		unlock_quest_by_id(next_id)
	available_quests.erase(quest)
	completed_quests.append(quest)
	SaveManager.save_game()

func apply_rewards(quest: Quest) -> void:
	for reward in quest.reward:
		match reward.reward_type:
			QuestReward.RewardType.ITEM:
				GameState.hero.inventory.add_potion(reward.item, reward.amount)
			QuestReward.RewardType.GOLD:
				GameState.hero.inventory.gold += reward.amount
			QuestReward.RewardType.EXPERIENCE:
				GameState.hero.gain_experience(reward.amount)
			QuestReward.RewardType.CLASS_WEAPON:
				var weapon = WeaponDatabase.get_random_weapon_for_class(GameState.hero.hero_class, reward.weapon_rarity)
				if weapon != null:
					GameState.hero.inventory.add_weapon_to_stash(weapon)

func new_game() -> void:
	locked_quests = []
	available_quests = []
	completed_quests = []
	for quest_res in QUEST_LIST:
		locked_quests.append(quest_res.duplicate(true))
	if locked_quests.size() > 0:
		unlock_quest_by_id(FIRST_QUEST_ID)

func unlock_quest_by_id(quest_id: int) -> void:
	for locked_quest in locked_quests.duplicate():
		if locked_quest.id == quest_id:
			locked_quests.erase(locked_quest)
			add_available_quest(locked_quest)
			return

func add_available_quest(quest: Quest) -> void:
	if quest in available_quests or quest in completed_quests:
		return
	available_quests.append(quest)
	quest.quest_completed.connect(_on_quest_completed)
