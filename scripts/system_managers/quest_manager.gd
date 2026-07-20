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

@export var locked_quests: Array[Quest] = []
@export var available_quests: Array[Quest] = []
@export var completed_quests: Array[Quest] = []

signal quest_activated(quest: Quest)
signal quest_progress_updated(quest: Quest)
signal quest_ready_to_turn_in(quest: Quest)
signal quest_turned_in(quest: Quest, rewards: Array[RewardEntry])

func new_game() -> void:
	locked_quests = []
	available_quests = []
	completed_quests = []
	for path in QUEST_PATHS:
		var quest := (load(path) as Quest).duplicate(true)
		locked_quests.append(quest)
	if locked_quests.size() > 0:
		unlock_quest_by_id(FIRST_QUEST_ID)
	_connect_signals()

func reconnect_signals() -> void:
	_connect_signals()

func disconnect_signals() -> void:
	if GameState.monster_killed.is_connected(_on_monster_killed):
		GameState.monster_killed.disconnect(_on_monster_killed)

func _connect_signals() -> void:
	if not GameState.monster_killed.is_connected(_on_monster_killed):
		GameState.monster_killed.connect(_on_monster_killed)

func _on_monster_killed(monster_id: MonsterLoader.MonsterID, location_id: String) -> void:
	for quest in get_active_quests():
		var previous_progress := quest.get_slain_count()
		var was_ready := quest.all_objectives_met()
		quest.slay_monster(monster_id, location_id)
		if quest.get_slain_count() != previous_progress:
			quest_progress_updated.emit(quest)
		if not was_ready and quest.all_objectives_met():
			quest_ready_to_turn_in.emit(quest)

func turn_in_quest(quest: Quest) -> Array[RewardEntry]:
	if quest not in available_quests:
		push_warning("QuestManager: quest '%s' not in available_quests" % quest.title)
		return []
	if not quest.all_objectives_met():
		push_warning("QuestManager: quest '%s' objectives not met" % quest.title)
		return []
	var entries: Array[RewardEntry] = []
	_apply_rewards(quest, entries)
	_apply_location_unlocks(quest)
	for next_id in quest.next_quests:
		unlock_quest_by_id(next_id)
	available_quests.erase(quest)
	completed_quests.append(quest)
	quest_turned_in.emit(quest, entries)
	SaveManager.save_game()
	if quest.final_quest:
		ScreenManager.go_to_screen(ScreenManager.ScreenName.VICTORY)
		return []
	return entries

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

func unlock_quest_by_id(quest_id: int) -> void:
	for locked_quest in locked_quests.duplicate():
		if locked_quest.id == quest_id:
			locked_quests.erase(locked_quest)
			add_available_quest(locked_quest)
			_reset_spawners_for_quest(locked_quest)
			return

func _reset_spawners_for_quest(quest: Quest) -> void:
	var locations_to_reset: Array[String] = []
	for objective in quest.objectives:
		if objective.location_id != "" and objective.location_id not in locations_to_reset:
			locations_to_reset.append(objective.location_id)
	for location_id in locations_to_reset:
		WorldManager.reset_location_spawners(location_id)

func add_available_quest(quest: Quest) -> void:
	if quest == null:
		push_warning("QuestManager: cannot add a null quest")
		return
	if has_quest_id(quest.id):
		push_warning("QuestManager: quest id %d is already tracked" % quest.id)
		return
	available_quests.append(quest)
	quest_activated.emit(quest)

func get_active_quests() -> Array[Quest]:
	var active: Array[Quest] = []
	for quest in available_quests:
		if not quest.completed:
			active.append(quest)
	return active

func get_completable_quests() -> Array[Quest]:
	var completable: Array[Quest] = []
	for quest in available_quests:
		if quest.all_objectives_met():
			completable.append(quest)
	return completable

func get_quest_by_id(quest_id: int) -> Quest:
	for quest in locked_quests:
		if quest.id == quest_id:
			return quest
	for quest in available_quests:
		if quest.id == quest_id:
			return quest
	for quest in completed_quests:
		if quest.id == quest_id:
			return quest
	return null

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

func has_completable_quests() -> bool:
	return not get_completable_quests().is_empty()
