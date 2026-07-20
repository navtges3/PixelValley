extends TestCase

const TEST_SAVE_SLOT := 999998


func run_tests() -> int:
	_begin_test_run()
	_prepare_game_state()
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
	var quest_document: Dictionary = SaveManager._load_json(TEST_SAVE_SLOT, "quests.json")
	var saved_data: Dictionary = quest_document.get("data", {})
	var saved_active_quests: Array = saved_data.get("active_quests", [])
	_expect_equal(saved_active_quests.size(), 1, "accepting a quest saves the active lifecycle state")
	var saved_quest: Dictionary = saved_active_quests[0]
	_expect_equal(saved_quest.get("id", 0), quest.id, "the accepted quest ID is persisted")

	quest.objectives[0].current_amount = quest.objectives[0].target_amount
	_expect_true(manager.mark_quest_ready(quest), "quest with met objectives becomes ready")
	_expect_true(manager.is_quest_ready(quest.id), "ready quest is tracked in the ready list")
	_expect_true(quest not in manager.active_quests, "ready quest leaves the active list")

	var starting_gold := GameState.hero.inventory.gold
	var reward_entries := manager.turn_in_quest(quest)
	_expect_true(manager.is_quest_completed(quest.id), "turned-in quest becomes completed")
	_expect_true(quest.completed, "turn-in records completion on the quest resource")
	_expect_true(quest not in manager.ready_quests, "completed quest leaves the ready list")
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
	quest.objectives[0].current_amount = 1

	_expect_true(manager.abandon_quest(quest), "active side quest can be abandoned")
	_expect_true(manager.is_quest_offered(quest.id), "abandoned side quest becomes offered again")
	_expect_equal(quest.objectives[0].current_amount, 0, "abandoning resets objective progress")


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
	var objective := QuestObjective.new()
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
func _cleanup() -> void:
	GameState.reset_state()
	if SaveManager.has_save_data(TEST_SAVE_SLOT):
		SaveManager.delete_slot(TEST_SAVE_SLOT)
