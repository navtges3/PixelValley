extends RefCounted
class_name QuestManager

enum LifecycleState {
	UNKNOWN,
	LOCKED,
	OFFERED,
	ACTIVE,
	READY,
	COMPLETED,
}

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
	"res://resources/quests/quest_11.tres",
	"res://resources/quests/quest_12.tres",
	"res://resources/quests/quest_13.tres",
]

const TUTORIAL_MAIN_START_ID: int = 110
const GOBLIN_FOREST_START_ID: int = 210
const ORC_WAR_CAMP_START_ID: int = 310
const OGRE_CAVE_START_ID: int = 410
const FINAL_QUEST_ID: int = 440
const TUTORIAL_SIDE_QUEST_START_ID: int = 1010
const FIRST_QUEST_ID: int = GOBLIN_FOREST_START_ID

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
signal tracked_quest_changed(quest_id: int)

var tracked_quest_id: int = -1

func new_game() -> void:
	locked_quests = []
	offered_quests = []
	active_quests = []
	ready_quests = []
	completed_quests = []
	tracked_quest_id = -1
	for path: String in QUEST_PATHS:
		var quest := (load(path) as Quest).duplicate(true)
		locked_quests.append(quest)
	for quest: Quest in locked_quests.duplicate():
		if quest.id == FIRST_QUEST_ID or quest.initially_unlocked:
			unlock_quest_by_id(quest.id)
	_connect_signals()

func reconnect_signals() -> void:
	_connect_signals()

func disconnect_signals() -> void:
	if GameState.gameplay_event.is_connected(_on_gameplay_event):
		GameState.gameplay_event.disconnect(_on_gameplay_event)

func unlock_quest_by_id(quest_id: int) -> bool:
	for quest in locked_quests.duplicate():
		if quest.id != quest_id:
			continue
		if _should_auto_activate(quest):
			return activate_quest(quest)
		return offer_quest(quest)
	push_warning("QuestMananager: locked quest id %d was not found" % quest_id)
	return false

func offer_quest(quest: Quest) -> bool:
	if quest == null:
		push_warning("QuestManager: cannot offer a null quest")
		return false
	if quest in offered_quests:
		return true
	var tracked_quest: Quest = get_quest_by_id(quest.id)
	if tracked_quest != null and tracked_quest != quest:
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
	if quest in ready_quests or quest in completed_quests:
		return false
	var existing_quest := get_quest_by_id(quest.id)
	if existing_quest != null and existing_quest != quest:
		return false
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
		return false
	_reset_quest_progress(quest)
	_remove_from_lifecycle_lists(quest)
	if quest.id == tracked_quest_id:
		_set_tracked_quest_id(-1)
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
		return false
	_remove_from_lifecycle_lists(quest)
	ready_quests.append(quest)
	quest_ready_to_turn_in.emit(quest)
	SaveManager.save_game()
	return true

func turn_in_quest(quest: Quest) -> Array[RewardEntry]:
	if quest == null:
		push_warning("QuestManager: cannot turn in a null quest")
		return []
	if quest not in ready_quests:
		return []
	_remove_from_lifecycle_lists(quest)
	if quest.id == tracked_quest_id:
		_set_tracked_quest_id(-1)
	quest.completed = true
	completed_quests.append(quest)
	var rewards: Array[RewardEntry] = RewardService.grant(quest.reward, GameState.hero)
	_apply_location_unlocks(quest)
	for next_id: int in quest.next_quests:
		unlock_quest_by_id(next_id)
	quest_turned_in.emit(quest, rewards)
	SaveManager.save_game()
	if quest.final_quest:
		ScreenManager.go_to_screen(ScreenManager.ScreenName.VICTORY)
	return rewards

func get_offered_quests() -> Array[Quest]:
	return offered_quests.duplicate()

func get_active_quests() -> Array[Quest]:
	return active_quests.duplicate()

func get_ready_quests() -> Array[Quest]:
	return ready_quests.duplicate()

func get_completed_quests() -> Array[Quest]:
	return completed_quests.duplicate()

func get_tracked_quest() -> Quest:
	if tracked_quest_id < 0:
		return null
	if not is_quest_active(tracked_quest_id) and not is_quest_ready(tracked_quest_id):
		_set_tracked_quest_id(-1)
		return null
	return get_quest_by_id(tracked_quest_id)

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

func get_quest_by_source(source_type: Quest.SourceType, source_id: String) -> Array[Quest]:
	var matches: Array[Quest] = []
	for quest: Quest in _get_all_quests():
		if quest.source_type == source_type and quest.source_id == source_id:
			matches.append(quest)
	return matches

func get_quest_state(quest_id: int) -> LifecycleState:
	if _contains_quest_id(locked_quests, quest_id):
		return LifecycleState.LOCKED
	if is_quest_offered(quest_id):
		return LifecycleState.OFFERED
	if is_quest_active(quest_id):
		return LifecycleState.ACTIVE
	if is_quest_ready(quest_id):
		return LifecycleState.READY
	if is_quest_completed(quest_id):
		return LifecycleState.COMPLETED
	return LifecycleState.UNKNOWN

static func get_defined_quest_ids() -> Array[int]:
	var ids: Array[int] = []
	for path: String in QUEST_PATHS:
		var quest := load(path) as Quest
		if quest != null:
			ids.append(quest.id)
	return ids

func add_missing_defined_quests() -> void:
	for path: String in QUEST_PATHS:
		var definition := load(path) as Quest
		if definition == null or has_quest_id(definition.id):
			continue
		var quest := definition.duplicate(true) as Quest
		locked_quests.append(quest)
		if quest.initially_unlocked:
			unlock_quest_by_id(quest.id)

func has_ready_quests() -> bool:
	return not ready_quests.is_empty()

func is_quest_offered(quest_id: int) -> bool:
	return _contains_quest_id(offered_quests, quest_id)

func is_quest_active(quest_id: int) -> bool:
	return _contains_quest_id(active_quests, quest_id)

func is_quest_ready(quest_id: int) -> bool:
	return _contains_quest_id(ready_quests, quest_id)

func is_quest_completed(quest_id: int) -> bool:
	return _contains_quest_id(completed_quests, quest_id)

func track_quest(quest_id: int) -> bool:
	if not is_quest_active(quest_id) and not is_quest_ready(quest_id):
		return false
	if tracked_quest_id == quest_id:
		return true
	_set_tracked_quest_id(quest_id)
	return true

func untrack_quest() -> void:
	_set_tracked_quest_id(-1)

func restore_tracked_quest_id(quest_id: int) -> void:
	tracked_quest_id = quest_id if (is_quest_active(quest_id) or is_quest_ready(quest_id)) else -1

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
	if not GameState.gameplay_event.is_connected(_on_gameplay_event):
		GameState.gameplay_event.connect(_on_gameplay_event)

func _contains_quest_id(quests: Array[Quest], quest_id: int) -> bool:
	for quest: Quest in quests:
		if quest.id == quest_id:
			return true
	return false

func _set_tracked_quest_id(quest_id: int) -> void:
	if tracked_quest_id == quest_id:
		return
	tracked_quest_id = quest_id
	tracked_quest_changed.emit(tracked_quest_id)

func _get_all_quests() -> Array[Quest]:
	var result: Array[Quest] = []
	result.append_array(locked_quests)
	result.append_array(offered_quests)
	result.append_array(active_quests)
	result.append_array(ready_quests)
	result.append_array(completed_quests)
	return result

func _remove_from_lifecycle_lists(quest: Quest) -> void:
	locked_quests.erase(quest)
	offered_quests.erase(quest)
	active_quests.erase(quest)
	ready_quests.erase(quest)
	completed_quests.erase(quest)

func _reset_quest_progress(quest: Quest) -> void:
	quest.completed = false
	quest.reset_objectives()

func _should_auto_activate(quest: Quest) -> bool:
	return quest.category == Quest.Category.MAIN and quest.source_type == Quest.SourceType.AUTOMATIC

func _on_gameplay_event(event: GameplayEvent) -> void:
	var has_unsaved_progress := false
	for quest: Quest in active_quests.duplicate():
		if not quest.apply_event(event):
			continue
		quest_progress_updated.emit(quest)
		if quest.objectives_met():
			mark_quest_ready(quest)
		else:
			has_unsaved_progress = true
	if has_unsaved_progress:
		SaveManager.save_game()

func _apply_location_unlocks(quest: Quest) -> void:
	for location_id in quest.unlocks_locations:
		WorldManager.unlock_location(location_id)

func _reset_spawners_for_quest(quest: Quest) -> void:
	for location_id: String in quest.get_activation_location_ids():
		WorldManager.reset_location_spawners(location_id)
