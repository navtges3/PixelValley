extends TestCase

const TEST_SAVE_SLOT := 999999

var _progress_counts: Dictionary[int, int] = {}
var _ready_counts: Dictionary[int, int] = {}
var _completion_counts: Dictionary[int, int] = {}
var _turn_in_counts: Dictionary[int, int] = {}

func run_tests() -> int:
	_begin_test_run()
	_progress_counts.clear()
	_ready_counts.clear()
	_completion_counts.clear()
	_turn_in_counts.clear()
	_prepare_game_state()
	_test_concurrent_quests_and_save_load()
	_test_main_quest_progression()
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

	var quick_quest := _make_kill_quest(101, MonsterLoader.MonsterID.GOBLIN, 1, "forest")
	var long_quest := _make_kill_quest(102, MonsterLoader.MonsterID.GOBLIN, 3, "forest")
	var unrelated_quest := _make_kill_quest(103, MonsterLoader.MonsterID.ORC, 1, "orc_war_camp")
	quick_quest.quest_completed.connect(_on_quest_completed)
	long_quest.quest_completed.connect(_on_quest_completed)
	unrelated_quest.quest_completed.connect(_on_quest_completed)
	manager.add_available_quest(quick_quest)
	manager.add_available_quest(long_quest)
	manager.add_available_quest(unrelated_quest)

	GameState.monster_killed.emit(MonsterLoader.MonsterID.GOBLIN, "forest")
	_expect_equal(quick_quest.get_slain_count(), 1, "one kill progresses the first matching quest")
	_expect_equal(long_quest.get_slain_count(), 1, "one kill progresses the second matching quest")
	_expect_equal(unrelated_quest.get_slain_count(), 0, "one kill does not progress an unrelated quest")
	_expect_equal(_progress_counts.get(101, 0), 1, "first matching quest emits one progress event")
	_expect_equal(_progress_counts.get(102, 0), 1, "second matching quest emits one progress event")
	_expect_equal(_progress_counts.get(103, 0), 0, "unrelated quest emits no progress event")
	_expect_equal(_ready_counts.get(101, 0), 1, "ready event emits when the quick quest completes")
	_expect_equal(_completion_counts.get(101, 0), 1, "completion event emits when the quick quest completes")

	GameState.monster_killed.emit(MonsterLoader.MonsterID.GOBLIN, "forest")
	_expect_equal(_progress_counts.get(101, 0), 1, "completed quest does not emit duplicate progress")
	_expect_equal(_ready_counts.get(101, 0), 1, "completed quest does not emit duplicate readiness")
	_expect_equal(_completion_counts.get(101, 0), 1, "completed quest does not emit duplicate completion")
	_expect_equal(long_quest.get_slain_count(), 2, "other active quest keeps progressing")

	manager.turn_in_quest(quick_quest)
	_expect_equal(_turn_in_counts.get(101, 0), 1, "turn-in event emits once")
	_expect_true(quick_quest in manager.completed_quests, "turned-in quest moves to completed quests")
	_expect_true(long_quest in manager.available_quests, "turning in one quest keeps the other available")
	_expect_equal(long_quest.get_slain_count(), 2, "turning in one quest preserves other quest progress")
	_expect_true(not long_quest.completed, "turning in one quest does not complete the other")

	SaveManager.save_game()
	SaveManager.load_game(TEST_SAVE_SLOT)
	var loaded_manager := GameState.quest_manager
	_connect_manager_counters(loaded_manager)
	var loaded_quick := loaded_manager.get_quest_by_id(101)
	var loaded_long := loaded_manager.get_quest_by_id(102)
	var loaded_unrelated := loaded_manager.get_quest_by_id(103)
	loaded_long.quest_completed.connect(_on_quest_completed)
	_expect_true(loaded_quick in loaded_manager.completed_quests, "save/load preserves the turned-in quest")
	_expect_equal(loaded_long.get_slain_count(), 2, "save/load preserves active quest progress")
	_expect_equal(loaded_unrelated.get_slain_count(), 0, "save/load preserves unrelated quest progress")

	var stale_progress_count: int = _progress_counts.get(102, 0)
	GameState.monster_killed.emit(MonsterLoader.MonsterID.GOBLIN, "forest")
	_expect_equal(loaded_long.get_slain_count(), 3, "loaded active quest continues progressing")
	_expect_equal(_progress_counts.get(102, 0), stale_progress_count + 1, "only the loaded manager emits progress")
	_expect_equal(_ready_counts.get(102, 0), 1, "loaded quest emits readiness once")
	_expect_equal(_completion_counts.get(102, 0), 1, "loaded quest emits completion once")

	GameState.monster_killed.emit(MonsterLoader.MonsterID.GOBLIN, "forest")
	_expect_equal(_progress_counts.get(102, 0), stale_progress_count + 1, "loaded completed quest emits no duplicate progress")
	_expect_equal(_ready_counts.get(102, 0), 1, "loaded completed quest emits no duplicate readiness")
	_expect_equal(_completion_counts.get(102, 0), 1, "loaded completed quest emits no duplicate completion")

func _test_main_quest_progression() -> void:
	GameState.quest_manager.disconnect_signals()
	var manager := QuestManager.new()
	GameState.quest_manager = manager
	manager.new_game()
	_connect_manager_counters(manager)
	var first_quest := manager.get_quest_by_id(QuestManager.FIRST_QUEST_ID)
	_expect_not_null(first_quest, "new game loads the first main quest")
	_expect_true(first_quest in manager.available_quests, "first main quest starts available")
	var previous_progress := first_quest.get_slain_count()
	GameState.monster_killed.emit(MonsterLoader.MonsterID.GOBLIN, "forest")
	_expect_equal(first_quest.get_slain_count(), previous_progress + 1, "main quest still progresses from its normal kill event")

func _make_kill_quest(
	quest_id: int,
	monster_id: MonsterLoader.MonsterID,
	target_amount: int,
	location_id: String
) -> Quest:
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

func _on_quest_completed(quest: Quest) -> void:
	_completion_counts[quest.id] = _completion_counts.get(quest.id, 0) + 1

func _on_quest_turned_in(quest: Quest, _rewards: Array[RewardEntry]) -> void:
	_turn_in_counts[quest.id] = _turn_in_counts.get(quest.id, 0) + 1

func _cleanup() -> void:
	GameState.reset_state()
	if SaveManager.has_save_data(TEST_SAVE_SLOT):
		SaveManager.delete_slot(TEST_SAVE_SLOT)
