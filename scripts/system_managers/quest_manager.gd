extends Resource
class_name QuestManager

const QUEST_PATHS := [
	"res://resources/quests/quest_01.tres",
	"res://resources/quests/quest_02.tres",
	"res://resources/quests/quest_03.tres",
	"res://resources/quests/quest_04.tres",
	"res://resources/quests/quest_05.tres",
	"res://resources/quests/quest_06.tres",
	"res://resources/quests/quest_07.tres",
	"res://resources/quests/quest_08.tres",
	"res://resources/quests/quest_09.tres",
	"res://resources/quests/quest_10.tres",
]

const FIRST_QUEST_ID := 1


static func get_defined_quest_ids() -> Array[int]:
	var ids: Array[int] = []
	for path: String in QUEST_PATHS:
		var quest := load(path) as Quest
		if quest != null:
			ids.append(quest.id)
	return ids

@export var locked_quests: Array[Quest] = []
@export var offered_quests: Array[Quest] = []
@export var active_quests: Array[Quest] = []
@export var ready_quests: Array[Quest] = []
@export var completed_quests: Array[Quest] = []

signal quest_offered(quest: Quest)
signal quest_accepted(quest: Quest)
signal quest_abandoned(quest: Quest)
signal quest_progress_updated(quest: Quest)
signal quest_ready_to_turn_in(quest: Quest)
signal quest_turned_in(quest: Quest, rewards: Array[RewardEntry])

func new_game() -> void:
	locked_quests = []
	offered_quests = []
	active_quests = []
	ready_quests = []
	completed_quests = []
	for path: String in QUEST_PATHS:
		var quest := (load(path) as Quest).duplicate(true)
		locked_quests.append(quest)
	if not locked_quests.is_empty():
		unlock_quest_by_id(FIRST_QUEST_ID)
	_connect_signals()

func reconnect_signals() -> void:
	_connect_signals()

func disconnect_signals() -> void:
	if GameState.monster_killed.is_connected(_on_monster_killed):
		GameState.monster_killed.disconnect(_on_monster_killed)

func offer_quest(quest: Quest) -> bool:
	if quest == null:
		push_warning("QuestManager: cannot offer a null quest")
		return false
	if quest in offered_quests:
		return true
	var tracked_quest: Quest = get_quest_by_id(quest.id)
	if tracked_quest != null and tracked_quest != quest:
		push_warning("QuestManager: quest id %d is already tracked" % quest.id)
		return false
	if quest in active_quests or quest in ready_quests or quest in completed_quests:
		push_warning("QuestManager: quest '%s' cannot be offered from its current state" % quest.title)
		return false
	_remove_from_lifecycle_lists(quest)
	offered_quests.append(quest)
	quest_offered.emit(quest)
	return true

func activate_quest(quest: Quest) -> bool:
	if quest == null:
		push_warning("QuestManager: cannot activate a null quest")
		return false
	if quest in active_quests:
		return true
	_remove_from_lifecycle_lists(quest)
	active_quests.append(quest)
	_reset_spawners_for_quest(quest)
	quest_accepted.emit(quest)
	return true

func accept_quest(quest: Quest) -> bool:
	if quest == null:
		push_warning("QuestManager: cannot accept a null quest")
		return false
	if quest not in offered_quests:
		push_warning("QuestManager: quest '%s' is not currently offered" % quest.title)
		return false
	if not activate_quest(quest):
		return false
	SaveManager.save_game()
	return true

func accept_quest_by_id(quest_id: int) -> bool:
	var quest := get_quest_by_id(quest_id)
	if quest == null:
		push_warning("QuestManager: unknown quest id %d" % quest_id)
		return false
	return accept_quest(quest)

func abandon_quest(quest: Quest) -> bool:
	if quest == null:
		push_warning("QuestManager: cannot abandon a null quest")
		return false
	if quest not in active_quests:
		push_warning("QuestManager: quest '%s' is not active" % quest.title)
		return false
	if quest.category == Quest.Category.MAIN:
		push_warning("QuestManager: main quest '%s' cannot be abandoned" % quest.title)
		return false
	_reset_quest_progress(quest)
	_remove_from_lifecycle_lists(quest)
	offered_quests.append(quest)
	quest_abandoned.emit(quest)
	SaveManager.save_game()
	return true

func mark_quest_ready(quest: Quest) -> bool:
	if quest == null:
		push_warning("QuestManager: cannot ready a null quest")
		return false
	if quest not in active_quests:
		push_warning("QuestManager: quest '%s' is not active" % quest.title)
		return false
	if not quest.objectives_met():
		push_warning("QuestManager: not all quest objectives met")
		return false
	_remove_from_lifecycle_lists(quest)
	ready_quests.append(quest)
	quest_ready_to_turn_in.emit(quest)
	SaveManager.save_game()
	return true

func turn_in_quest(quest: Quest) -> Array[RewardEntry]:
	if quest == null:
		return []
	if quest not in ready_quests:
		push_warning("QuestManager: quest '%s' is not ready to turn in" % quest.title)
		return []
	var entries: Array[RewardEntry] = []
	_remove_from_lifecycle_lists(quest)
	quest.completed = true
	completed_quests.append(quest)
	_apply_rewards(quest, entries)
	_apply_location_unlocks(quest)
	for next_id: int in quest.next_quests:
		unlock_quest_by_id(next_id)
	quest_turned_in.emit(quest, entries)
	SaveManager.save_game()
	if quest.final_quest:
		ScreenManager.go_to_screen(ScreenManager.ScreenName.VICTORY)
	return entries

func unlock_quest_by_id(quest_id: int) -> bool:
	for quest in locked_quests.duplicate():
		if quest.id != quest_id:
			continue
		if _should_auto_activate(quest):
			return activate_quest(quest)
		return offer_quest(quest)
	push_warning("QuestMananager: locked quest id %d was not found" % quest_id)
	return false

func get_offered_quests() -> Array[Quest]:
	return offered_quests.duplicate()

func get_active_quests() -> Array[Quest]:
	return active_quests.duplicate()

func get_ready_quests() -> Array[Quest]:
	return ready_quests.duplicate()

func get_completed_quests() -> Array[Quest]:
	return completed_quests.duplicate()

func has_ready_quests() -> bool:
	return not ready_quests.is_empty()

func get_quest_by_id(quest_id: int) -> Quest:
	for quest: Quest in locked_quests:
		if quest.id == quest_id:
			return quest
	for quest: Quest in offered_quests:
		if quest.id == quest_id:
			return quest
	for quest: Quest in active_quests:
		if quest.id == quest_id:
			return quest
	for quest: Quest in ready_quests:
		if quest.id == quest_id:
			return quest
	for quest: Quest in completed_quests:
		if quest.id == quest_id:
			return quest
	return null

func is_quest_offered(quest_id: int) -> bool:
	return _contains_quest_id(offered_quests, quest_id)

func is_quest_active(quest_id: int) -> bool:
	return _contains_quest_id(active_quests, quest_id)

func is_quest_ready(quest_id: int) -> bool:
	return _contains_quest_id(ready_quests, quest_id)

func is_quest_completed(quest_id: int) -> bool:
	return _contains_quest_id(completed_quests, quest_id)

func filter_quests_by_category(quests: Array[Quest], category: Quest.Category) -> Array[Quest]:
	var matches: Array[Quest] = []
	for quest in quests:
		if quest.category == category:
			matches.append(quest)
	return matches

func filter_quests_by_source(quests: Array[Quest], source_type: Quest.SourceType, source_id: String = "") -> Array[Quest]:
	var matches: Array[Quest] = []
	for quest in quests:
		if quest.source_type != source_type:
			continue
		if not source_id.is_empty() and quest.source_id != source_id:
			continue
		matches.append(quest)
	return matches

func has_quest_id(quest_id: int) -> bool:
	return get_quest_by_id(quest_id) != null

func _connect_signals() -> void:
	if not GameState.monster_killed.is_connected(_on_monster_killed):
		GameState.monster_killed.connect(_on_monster_killed)

func _contains_quest_id(quests: Array[Quest], quest_id: int) -> bool:
	for quest: Quest in quests:
		if quest.id == quest_id:
			return true
	return false

func _remove_from_lifecycle_lists(quest: Quest) -> void:
	locked_quests.erase(quest)
	offered_quests.erase(quest)
	active_quests.erase(quest)
	ready_quests.erase(quest)
	completed_quests.erase(quest)

func _reset_quest_progress(quest: Quest) -> void:
	quest.completed = false
	for objective: QuestObjective in quest.objectives:
		objective.current_amount = 0

func _should_auto_activate(quest: Quest) -> bool:
	return quest.category == Quest.Category.MAIN and quest.source_type == Quest.SourceType.AUTOMATIC

func _on_monster_killed(monster_id: MonsterLoader.MonsterID, location_id: String) -> void:
	for quest: Quest in active_quests.duplicate():
		var previous_progress := quest.get_slain_count()
		var was_ready := quest.objectives_met()
		quest.slay_monster(monster_id, location_id)
		if quest.get_slain_count() != previous_progress:
			quest_progress_updated.emit(quest)
		if not was_ready and quest.objectives_met():
			mark_quest_ready(quest)

func _apply_rewards(quest: Quest, entries: Array[RewardEntry]) -> void:
	var hero := GameState.hero
	hero.gain_experience(quest.reward.experience)
	hero.inventory.gold += quest.reward.gold
	entries.append(RewardEntry.experience(quest.reward.experience))
	entries.append(RewardEntry.gold(quest.reward.gold))
	for item_id in quest.reward.items:
		hero.inventory.add_potion(item_id, 1)
		entries.append(RewardEntry.potion(item_id, 1))
	if quest.reward.random_weapon:
		_apply_weapon_rewards(quest.reward.rarity, entries)

func _apply_weapon_rewards(rarity: Item.Rarity, entries: Array[RewardEntry]) -> void:
	var weapon_id := WeaponDatabase.get_random_unowned_weapon_id_for_class(GameState.hero.hero_class, rarity)
	if weapon_id != "":
		GameState.hero.inventory.add_weapon_to_stash(weapon_id)
		entries.append(RewardEntry.weapon(weapon_id))
	else:
		var gold := WeaponDatabase.get_gold_fallback_for_rarity(rarity)
		GameState.hero.inventory.gold += gold
		entries.append(RewardEntry.weapon_sold(weapon_id, gold))

func _apply_location_unlocks(quest: Quest) -> void:
	for location_id in quest.unlocks_locations:
		WorldManager.unlock_location(location_id)

func _reset_spawners_for_quest(quest: Quest) -> void:
	var locations_to_reset: Array[String] = []
	for objective in quest.objectives:
		if objective.location_id != "" and objective.location_id not in locations_to_reset:
			locations_to_reset.append(objective.location_id)
	for location_id in locations_to_reset:
		WorldManager.reset_location_spawners(location_id)
