extends RefCounted
class_name NpcQuestDialogueController

signal state_changed

const STATE_CONTEXT: Dictionary[QuestManager.LifecycleState, StringName] = {
	QuestManager.LifecycleState.UNKNOWN: &"unavailable",
	QuestManager.LifecycleState.LOCKED: &"locked",
	QuestManager.LifecycleState.OFFERED: &"offered",
	QuestManager.LifecycleState.ACTIVE: &"active",
	QuestManager.LifecycleState.READY: &"ready",
	QuestManager.LifecycleState.COMPLETED: &"completed",
}

const STATE_PRIORITY: Dictionary[QuestManager.LifecycleState, int] = {
	QuestManager.LifecycleState.READY: 0,
	QuestManager.LifecycleState.OFFERED: 1,
	QuestManager.LifecycleState.ACTIVE: 2,
	QuestManager.LifecycleState.LOCKED: 3,
	QuestManager.LifecycleState.COMPLETED: 4,
	QuestManager.LifecycleState.UNKNOWN: 5,
}

var _manager: QuestManager = null

func set_quest_manager(manager: QuestManager) -> void:
	if _manager == manager:
		return
	_disconnect_manager()
	_manager = manager
	_connect_manager()
	state_changed.emit()

func clear_quest_manager() -> void:
	_disconnect_manager()
	_manager = null

func build_context(npc_id: StringName, location_id: StringName) -> Dictionary[StringName, Variant]:
	var context: Dictionary[StringName, Variant] = {
		&"npc_id": npc_id,
		&"location_id": location_id,
		&"quest_id": -1,
		&"quest_state": &"unavailable",
		&"has_delivery_items": false,
	}
	if _manager == null:
		return context
	var quest := _resolve_primary_source_quest(npc_id)
	if quest != null:
		var state := _manager.get_quest_state(quest.id)
		context[&"quest_id"] = quest.id
		context[&"quest_state"] = STATE_CONTEXT.get(state, &"unavailable")
	context[&"has_delivery_items"] = _has_delivery_items(npc_id)
	return context

func handle_action(action: DialogueAction, context: Dictionary[StringName, Variant]) -> Array[RewardEntry]:
	var rewards: Array[RewardEntry] = []
	if _manager == null or action == null:
		return rewards
	var quest_id := int(context.get(&"quest_id", -1))
	var quest := _manager.get_quest_by_id(quest_id)
	match action.action_id:
		&"accept_quest":
			if quest != null and _manager.is_quest_offered(quest.id):
				_manager.accept_quest(quest)
		&"decline_quest":
			# Declining intentionally preserves the offered lifecycle state.
			pass
		&"deliver_quest_items":
			_deliver_items(StringName(context.get(&"npc_id", &"")))
		&"turn_in_quest":
			if quest != null and _manager.is_quest_ready(quest.id):
				rewards = _manager.turn_in_quest(quest)
	return rewards

func get_npc_status(npc_id: StringName) -> NpcActor.Status:
	if _manager == null:
		return NpcActor.Status.NONE
	var quests := _manager.get_quest_by_source(Quest.SourceType.NPC, String(npc_id))
	for quest: Quest in quests:
		if _manager.is_quest_ready(quest.id):
			return NpcActor.Status.QUEST_READY
	for quest: Quest in quests:
		if _manager.is_quest_offered(quest.id):
			return NpcActor.Status.QUEST_AVAILABLE
	return NpcActor.Status.NONE

func _resolve_primary_source_quest(npc_id: StringName) -> Quest:
	var quests := _manager.get_quest_by_source(Quest.SourceType.NPC, String(npc_id))
	var result: Quest = null
	var result_priority: int = STATE_PRIORITY[QuestManager.LifecycleState.UNKNOWN]
	for quest: Quest in quests:
		var state := _manager.get_quest_state(quest.id)
		var priority: int = STATE_PRIORITY.get(state, STATE_PRIORITY[QuestManager.LifecycleState.UNKNOWN])
		if (result == null or priority < result_priority
			or (priority == result_priority and quest.id < result.id)):
			result = quest
			result_priority = priority
	return result

func _has_delivery_items(npc_id: StringName) -> bool:
	if GameState.hero == null or GameState.hero.inventory == null:
		return false
	for quest: Quest in _get_sorted_active_quests():
		for objective: QuestObjective in quest.objectives:
			var delivery := objective as DeliveryQuestObjective
			if delivery == null or delivery.is_complete():
				continue
			if delivery.target_npc_id != npc_id:
				continue
			var remaining := delivery.target_amount - delivery.current_amount
			if GameState.hero.inventory.get_potion_count(delivery.item_id) >= remaining:
				return true
	return false

func _deliver_items(npc_id: StringName) -> bool:
	if GameState.hero == null or GameState.hero.inventory == null:
		return false
	for quest: Quest in _get_sorted_active_quests():
		for objective: QuestObjective in quest.objectives:
			var delivery := objective as DeliveryQuestObjective
			if delivery == null or delivery.is_complete():
				continue
			if delivery.target_npc_id != npc_id:
				continue
			var remaining := delivery.target_amount - delivery.current_amount
			if not GameState.hero.inventory.remove_potions(delivery.item_id, remaining):
				return false
			GameState.gameplay_event.emit(
				ItemDeliveredEvent.new(npc_id, delivery.item_id, remaining)
			)
			return true
	return false

func _get_sorted_active_quests() -> Array[Quest]:
	var quests := _manager.get_active_quests()
	quests.sort_custom(func(a: Quest, b: Quest) -> bool: return a.id < b.id)
	return quests

func _connect_manager() -> void:
	if _manager == null:
		return
	_manager.quest_offered.connect(_on_quest_changed)
	_manager.quest_accepted.connect(_on_quest_changed)
	_manager.quest_abandoned.connect(_on_quest_changed)
	_manager.quest_progress_updated.connect(_on_quest_changed)
	_manager.quest_ready_to_turn_in.connect(_on_quest_changed)
	_manager.quest_turned_in.connect(_on_quest_turned_in)

func _disconnect_manager() -> void:
	if _manager == null:
		return
	if _manager.quest_offered.is_connected(_on_quest_changed):
		_manager.quest_offered.disconnect(_on_quest_changed)
	if _manager.quest_accepted.is_connected(_on_quest_changed):
		_manager.quest_accepted.disconnect(_on_quest_changed)
	if _manager.quest_abandoned.is_connected(_on_quest_changed):
		_manager.quest_abandoned.disconnect(_on_quest_changed)
	if _manager.quest_progress_updated.is_connected(_on_quest_changed):
		_manager.quest_progress_updated.disconnect(_on_quest_changed)
	if _manager.quest_ready_to_turn_in.is_connected(_on_quest_changed):
		_manager.quest_ready_to_turn_in.disconnect(_on_quest_changed)
	if _manager.quest_turned_in.is_connected(_on_quest_turned_in):
		_manager.quest_turned_in.disconnect(_on_quest_turned_in)

func _on_quest_changed(_quest: Quest) -> void:
	state_changed.emit()

func _on_quest_turned_in(_quest: Quest, _rewards: Array[RewardEntry]) -> void:
	state_changed.emit()
