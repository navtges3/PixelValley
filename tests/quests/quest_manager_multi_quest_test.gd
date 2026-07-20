extends TestCase

const TEST_SAVE_SLOT := 999999
const QUEST_SAVE_MIGRATOR := preload("res://scripts/save/quest_save_migrator.gd")

var _progress_counts: Dictionary[int, int] = {}
var _ready_counts: Dictionary[int, int] = {}
var _turn_in_counts: Dictionary[int, int] = {}

func run_tests() -> int:
	_begin_test_run()
	_progress_counts.clear()
	_ready_counts.clear()
	_turn_in_counts.clear()
	_prepare_game_state()
	_test_concurrent_quests_and_save_load()
	_test_main_quest_progression()
	_test_quest_metadata_defaults_and_queries()
	_cleanup()
	return _finish_test_run("Quest manager multi-quest tests")

func _prepare_game_state() -> void:
	GameState.reset_state()
	GameState.hero = HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	GameState.hero.name = "Quest Test Hero"
	GameState.village = Village.new()
	GameState.village.name = "Quest Test Village"
	GameState.village.inn = Inn.new()
	GameState.village.potion_shop = Shop.new()
	GameState.village.weapon_shop = Shop.new()
	GameState.player_location = {
		"scene": ScreenManager.ScreenName.VALLEY,
		"entrance_id": ""
	}
	WorldManager.reset()
	SaveManager.save_slot = TEST_SAVE_SLOT

func _test_concurrent_quests_and_save_load() -> void:
	var manager := QuestManager.new()
	GameState.quest_manager = manager
	manager.reconnect_signals()
	_connect_manager_counters(manager)

	var quick_quest := _make_kill_quest(1, MonsterLoader.MonsterID.GOBLIN, 1, "forest")
	var long_quest := _make_kill_quest(2, MonsterLoader.MonsterID.GOBLIN, 3, "forest")
	var unrelated_quest := _make_kill_quest(3, MonsterLoader.MonsterID.ORC, 1, "orc_war_camp")
	quick_quest.category = Quest.Category.SIDE
	quick_quest.source_type = Quest.SourceType.QUEST_BOARD
	quick_quest.source_id = "valley_board"
	manager.activate_quest(quick_quest)
	manager.activate_quest(long_quest)
	manager.activate_quest(unrelated_quest)

	GameState.monster_killed.emit(MonsterLoader.MonsterID.GOBLIN, "forest")
	_expect_equal(quick_quest.get_slain_count(), 1, "one kill progresses the first matching quest")
	_expect_equal(long_quest.get_slain_count(), 1, "one kill progresses the second matching quest")
	_expect_equal(unrelated_quest.get_slain_count(), 0, "one kill does not progress an unrelated quest")
	_expect_equal(_progress_counts.get(1, 0), 1, "first matching quest emits one progress event")
	_expect_equal(_progress_counts.get(2, 0), 1, "second matching quest emits one progress event")
	_expect_equal(_progress_counts.get(3, 0), 0, "unrelated quest emits no progress event")
	_expect_equal(_ready_counts.get(1, 0), 1, "ready event emits when the quick quest completes")
	_expect_true(quick_quest in manager.ready_quests, "completed objectives move the quick quest to ready")
	_expect_true(quick_quest not in manager.active_quests, "ready quest stops receiving progress")

	GameState.monster_killed.emit(MonsterLoader.MonsterID.GOBLIN, "forest")
	_expect_equal(_progress_counts.get(1, 0), 1, "completed quest does not emit duplicate progress")
	_expect_equal(_ready_counts.get(1, 0), 1, "completed quest does not emit duplicate readiness")
	_expect_equal(long_quest.get_slain_count(), 2, "other active quest keeps progressing")

	manager.turn_in_quest(quick_quest)
	_expect_equal(_turn_in_counts.get(1, 0), 1, "turn-in event emits once")
	_expect_true(quick_quest in manager.completed_quests, "turned-in quest moves to completed quests")
	_expect_true(long_quest in manager.active_quests, "turning in one quest keeps the other active")
	_expect_equal(long_quest.get_slain_count(), 2, "turning in one quest preserves other quest progress")
	_expect_true(not long_quest.completed, "turning in one quest does not complete the other")

	SaveManager.save_game()
	var quest_document: Dictionary = SaveManager._load_json(TEST_SAVE_SLOT, "quests.json")
	_expect_equal(
		quest_document.get("schema_version", 0),
		QUEST_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION,
		"quest saves include the current schema version"
	)
	SaveManager.load_game(TEST_SAVE_SLOT)
	var loaded_manager := GameState.quest_manager
	_connect_manager_counters(loaded_manager)
	var loaded_quick := loaded_manager.get_quest_by_id(1)
	var loaded_long := loaded_manager.get_quest_by_id(2)
	var loaded_unrelated := loaded_manager.get_quest_by_id(3)
	_expect_true(loaded_quick in loaded_manager.completed_quests, "save/load preserves the turned-in quest")
	_expect_equal(loaded_quick.category, Quest.Category.SIDE, "save/load preserves quest category")
	_expect_equal(loaded_quick.source_type, Quest.SourceType.QUEST_BOARD, "save/load preserves quest source type")
	_expect_equal(loaded_quick.source_id, "valley_board", "save/load preserves quest source ID")
	_expect_equal(loaded_long.get_slain_count(), 2, "save/load preserves active quest progress")
	_expect_equal(loaded_unrelated.get_slain_count(), 0, "save/load preserves unrelated quest progress")

	var stale_progress_count: int = _progress_counts.get(2, 0)
	GameState.monster_killed.emit(MonsterLoader.MonsterID.GOBLIN, "forest")
	_expect_equal(loaded_long.get_slain_count(), 3, "loaded active quest continues progressing")
	_expect_equal(_progress_counts.get(2, 0), stale_progress_count + 1, "only the loaded manager emits progress")
	_expect_equal(_ready_counts.get(2, 0), 1, "loaded quest emits readiness once")
	_expect_true(loaded_long in loaded_manager.ready_quests, "loaded quest moves to ready after its final kill")

	GameState.monster_killed.emit(MonsterLoader.MonsterID.GOBLIN, "forest")
	_expect_equal(_progress_counts.get(2, 0), stale_progress_count + 1, "loaded completed quest emits no duplicate progress")
	_expect_equal(_ready_counts.get(2, 0), 1, "loaded completed quest emits no duplicate readiness")

func _test_main_quest_progression() -> void:
	GameState.quest_manager.disconnect_signals()
	var manager := QuestManager.new()
	GameState.quest_manager = manager
	manager.new_game()
	_connect_manager_counters(manager)
	var first_quest := manager.get_quest_by_id(QuestManager.FIRST_QUEST_ID)
	_expect_not_null(first_quest, "new game loads the first main quest")
	_expect_true(first_quest in manager.active_quests, "first automatic main quest starts active")
	_expect_equal(first_quest.category, Quest.Category.MAIN, "existing quest resources default to main")
	_expect_equal(first_quest.source_type, Quest.SourceType.AUTOMATIC, "existing quest resources default to automatic activation")
	var previous_progress := first_quest.get_slain_count()
	GameState.monster_killed.emit(MonsterLoader.MonsterID.GOBLIN, "forest")
	_expect_equal(first_quest.get_slain_count(), previous_progress + 1, "main quest still progresses from its normal kill event")

func _test_quest_metadata_defaults_and_queries() -> void:
	var manager := QuestManager.new()

	var main_quest := _make_kill_quest(201, MonsterLoader.MonsterID.GOBLIN, 1, "forest")

	var board_side_quest := _make_kill_quest(202, MonsterLoader.MonsterID.GOBLIN, 1, "forest")
	board_side_quest.category = Quest.Category.SIDE
	board_side_quest.source_type = Quest.SourceType.QUEST_BOARD
	board_side_quest.source_id = "valley_board"

	var npc_side_quest := _make_kill_quest(203, MonsterLoader.MonsterID.ORC, 1, "orc_war_camp")
	npc_side_quest.category = Quest.Category.SIDE
	npc_side_quest.source_type = Quest.SourceType.NPC
	npc_side_quest.source_id = "npc_blacksmith"

	manager.activate_quest(main_quest)
	manager.offer_quest(board_side_quest)
	manager.offer_quest(npc_side_quest)

	_expect_equal(main_quest.category, Quest.Category.MAIN, "new quests default to the main category")
	_expect_equal(main_quest.source_type, Quest.SourceType.AUTOMATIC, "new quests default to automatic activation")

	var side_quests := manager.filter_quests_by_category(manager.get_offered_quests(), Quest.Category.SIDE)
	_expect_equal(side_quests.size(), 2, "category query returns both side quests")

	var board_quests := manager.filter_quests_by_source(
		manager.get_offered_quests(), Quest.SourceType.QUEST_BOARD, "valley_board"
	)
	_expect_equal(board_quests.size(), 1, "source query can identify a specific quest board")
	_expect_true(board_side_quest in board_quests, "source query returns the matching board quest")

	var legacy_data := {
		"id": 204,
		"title": "Legacy Quest",
		"description": "Saved before quest metadata existed.",
		"objectives": [],
		"reward": {},
	}
	var legacy_quest := SaveManager._load_quest(legacy_data)
	_expect_equal(legacy_quest.category, Quest.Category.MAIN, "legacy saves default quests to main")
	_expect_equal(legacy_quest.source_type, Quest.SourceType.AUTOMATIC, "legacy saves default quests to automatic activation")
	_expect_equal(legacy_quest.source_id, "", "legacy saves default to an empty source ID")

func _make_kill_quest(quest_id: int, monster_id: MonsterLoader.MonsterID, target_amount: int, location_id: String) -> Quest:
	var objective := QuestObjective.new()
	objective.monster_id = monster_id
	objective.target_amount = target_amount
	objective.location_id = location_id
	var quest := Quest.new()
	quest.id = quest_id
	quest.title = "Test Quest %d" % quest_id
	quest.objectives.append(objective)
	return quest

func _connect_manager_counters(manager: QuestManager) -> void:
	manager.quest_progress_updated.connect(_on_quest_progress_updated)
	manager.quest_ready_to_turn_in.connect(_on_quest_ready_to_turn_in)
	manager.quest_turned_in.connect(_on_quest_turned_in)

func _on_quest_progress_updated(quest: Quest) -> void:
	_progress_counts[quest.id] = _progress_counts.get(quest.id, 0) + 1

func _on_quest_ready_to_turn_in(quest: Quest) -> void:
	_ready_counts[quest.id] = _ready_counts.get(quest.id, 0) + 1

func _on_quest_turned_in(quest: Quest, _rewards: Array[RewardEntry]) -> void:
	_turn_in_counts[quest.id] = _turn_in_counts.get(quest.id, 0) + 1

func _cleanup() -> void:
	GameState.reset_state()
	if SaveManager.has_save_data(TEST_SAVE_SLOT):
		SaveManager.delete_slot(TEST_SAVE_SLOT)
