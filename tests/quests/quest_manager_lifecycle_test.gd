extends TestCase

const TEST_SAVE_SLOT := 999998

var _tracked_change_ids: Array[int] = []


func run_tests() -> int:
	_begin_test_run()
	_prepare_game_state()
	_test_tracking_rules_and_signals()
	_test_locked_offer_accept_ready_and_turn_in()
	_test_abandon_side_quest()
	_test_invalid_transitions()
	_cleanup()
	return _finish_test_run("Quest manager lifecycle tests")


func _prepare_game_state() -> void:
	GameState.reset_state()
	GameState.hero = HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	GameState.hero.name = "Lifecycle Test Hero"
	GameState.village = Village.new()
	GameState.village.name = "Lifecycle Test Village"
	GameState.village.inn = Inn.new()
	GameState.village.potion_shop = Shop.new()
	GameState.village.weapon_shop = Shop.new()
	GameState.player_location = {
		"scene": ScreenManager.ScreenName.VALLEY,
		"entrance_id": "",
	}
	WorldManager.reset()
	SaveManager.save_slot = TEST_SAVE_SLOT


func _test_tracking_rules_and_signals() -> void:
	var manager := QuestManager.new()
	GameState.quest_manager = manager
	_tracked_change_ids.clear()
	manager.tracked_quest_changed.connect(_on_tracked_quest_changed)

	var first_quest := _make_side_quest(104)
	var second_quest := _make_side_quest(105)
	var offered_quest := _make_side_quest(106)
	var locked_quest := _make_side_quest(107)
	var completed_quest := _make_side_quest(108)
	completed_quest.completed = true

	manager.activate_quest(first_quest)
	manager.activate_quest(second_quest)
	manager.offer_quest(offered_quest)
	manager.locked_quests.append(locked_quest)
	manager.completed_quests.append(completed_quest)

	_expect_true(not manager.track_quest(offered_quest.id), "offered quests cannot be tracked")
	_expect_true(not manager.track_quest(locked_quest.id), "locked quests cannot be tracked")
	_expect_true(not manager.track_quest(completed_quest.id), "completed quests cannot be tracked")
	_expect_true(not manager.track_quest(999), "unknown quest IDs cannot be tracked")
	_expect_equal(_tracked_change_ids.size(), 0, "rejected tracking requests emit no change signal")

	_expect_true(manager.track_quest(first_quest.id), "an active quest can be tracked")
	_expect_equal(manager.tracked_quest_id, first_quest.id, "tracking stores the stable quest ID")
	_expect_true(manager.get_tracked_quest() == first_quest, "the tracked quest resolves from its ID")
	_expect_equal(_tracked_change_ids, [first_quest.id], "tracking emits the tracked quest ID")

	_expect_true(manager.track_quest(first_quest.id), "tracking the current quest is idempotent")
	_expect_equal(_tracked_change_ids.size(), 1, "tracking the same quest does not emit twice")

	_expect_true(manager.track_quest(second_quest.id), "tracking another active quest succeeds")
	_expect_equal(manager.tracked_quest_id, second_quest.id, "new tracking replaces the previous quest")
	_expect_equal(_tracked_change_ids.back(), second_quest.id, "replacement emits the new tracked ID")

	manager.untrack_quest()
	_expect_equal(manager.tracked_quest_id, -1, "untracking clears the tracked ID")
	_expect_true(manager.get_tracked_quest() == null, "no quest resolves after untracking")
	_expect_equal(_tracked_change_ids.back(), -1, "untracking emits the empty tracking ID")
	var changes_after_untrack := _tracked_change_ids.size()
	manager.untrack_quest()
	_expect_equal(_tracked_change_ids.size(), changes_after_untrack, "repeated untracking emits no duplicate signal")

	manager.track_quest(first_quest.id)
	manager.active_quests.erase(first_quest)
	_expect_true(manager.get_tracked_quest() == null, "a stale tracked quest resolves safely to null")
	_expect_equal(manager.tracked_quest_id, -1, "resolving stale tracking clears its stored ID")
	_expect_equal(_tracked_change_ids.back(), -1, "stale tracking cleanup emits an untracked signal")


func _test_locked_offer_accept_ready_and_turn_in() -> void:
	var manager := QuestManager.new()
	GameState.quest_manager = manager
	var quest := _make_side_quest(101)
	quest.reward.gold = 25
	manager.locked_quests.append(quest)

	_expect_true(manager.unlock_quest_by_id(quest.id), "unlocking a side quest succeeds")
	_expect_true(manager.is_quest_offered(quest.id), "unlocked side quest becomes offered")
	_expect_true(quest not in manager.locked_quests, "offered quest leaves the locked list")
	_expect_true(manager.accept_quest_by_id(quest.id), "offered quest can be accepted")
	_expect_true(manager.is_quest_active(quest.id), "accepted quest becomes active")
	_expect_true(quest not in manager.offered_quests, "accepted quest leaves the offered list")
	_expect_true(manager.track_quest(quest.id), "accepted quest can be tracked")
	var quest_document: Dictionary = SaveManager._load_json(TEST_SAVE_SLOT, "quests.json")
	var saved_data: Dictionary = quest_document.get("data", {})
	var saved_active_quests: Array = saved_data.get("active_quests", [])
	_expect_equal(saved_active_quests.size(), 1, "accepting a quest saves the active lifecycle state")
	var saved_quest: Dictionary = saved_active_quests[0]
	_expect_equal(saved_quest.get("id", 0), quest.id, "the accepted quest ID is persisted")

	var objective := quest.objectives[0] as KillQuestObjective
	objective.current_amount = objective.target_amount
	_expect_true(manager.mark_quest_ready(quest), "quest with met objectives becomes ready")
	_expect_true(manager.is_quest_ready(quest.id), "ready quest is tracked in the ready list")
	_expect_true(quest not in manager.active_quests, "ready quest leaves the active list")
	_expect_equal(manager.tracked_quest_id, quest.id, "a tracked quest remains tracked while ready")

	var starting_gold := GameState.hero.inventory.gold
	var reward_entries := manager.turn_in_quest(quest)
	_expect_true(manager.is_quest_completed(quest.id), "turned-in quest becomes completed")
	_expect_true(quest.completed, "turn-in records completion on the quest resource")
	_expect_true(quest not in manager.ready_quests, "completed quest leaves the ready list")
	_expect_equal(manager.tracked_quest_id, -1, "turning in the tracked quest clears tracking")
	_expect_equal(
		GameState.hero.inventory.gold,
		starting_gold + quest.reward.gold,
		"turn-in grants the authored quest reward"
	)
	_expect_equal(reward_entries.size(), 1, "turn-in reports the applied quest reward")
	var repeated_entries := manager.turn_in_quest(quest)
	_expect_equal(repeated_entries.size(), 0, "completed quest cannot grant rewards again")
	_expect_equal(
		GameState.hero.inventory.gold,
		starting_gold + quest.reward.gold,
		"repeated turn-in does not duplicate quest rewards"
	)


func _test_abandon_side_quest() -> void:
	var manager := QuestManager.new()
	GameState.quest_manager = manager
	var quest := _make_side_quest(102)
	manager.offer_quest(quest)
	manager.accept_quest(quest)
	manager.track_quest(quest.id)
	var objective := quest.objectives[0] as KillQuestObjective
	objective.current_amount = 1

	_expect_true(manager.abandon_quest(quest), "active side quest can be abandoned")
	_expect_true(manager.is_quest_offered(quest.id), "abandoned side quest becomes offered again")
	_expect_equal(objective.current_amount, 0, "abandoning resets objective progress")
	_expect_equal(manager.tracked_quest_id, -1, "abandoning the tracked quest clears tracking")


func _test_invalid_transitions() -> void:
	var manager := QuestManager.new()
	GameState.quest_manager = manager
	var main_quest := _make_side_quest(103)
	main_quest.category = Quest.Category.MAIN
	manager.activate_quest(main_quest)
	var abandoned_main := manager.abandon_quest(main_quest)
	_expect_true(not abandoned_main, "active main quest cannot be abandoned")

	var duplicate_quest := _make_side_quest(main_quest.id)
	var offered_duplicate := manager.offer_quest(duplicate_quest)
	_expect_true(not offered_duplicate, "duplicate tracked quest ID cannot be offered")
	var marked_ready := manager.mark_quest_ready(main_quest)
	_expect_true(not marked_ready, "quest with unmet objectives cannot become ready")


func _make_side_quest(quest_id: int) -> Quest:
	var objective := KillQuestObjective.new()
	objective.monster_id = MonsterLoader.MonsterID.GOBLIN
	objective.target_amount = 2
	objective.location_id = "forest"
	var quest := Quest.new()
	quest.id = quest_id
	quest.title = "Lifecycle Quest %d" % quest_id
	quest.category = Quest.Category.SIDE
	quest.source_type = Quest.SourceType.QUEST_BOARD
	quest.source_id = "test_board"
	quest.objectives.append(objective)
	return quest


func _on_tracked_quest_changed(quest_id: int) -> void:
	_tracked_change_ids.append(quest_id)


func _cleanup() -> void:
	GameState.reset_state()
	if SaveManager.has_save_data(TEST_SAVE_SLOT):
		SaveManager.delete_slot(TEST_SAVE_SLOT)
