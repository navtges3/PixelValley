extends TestCase

const TEST_SAVE_SLOT: int = 999995
const DIALOGUE_SAVE_MIGRATOR := preload(
	"res://scripts/save/dialogue_save_migrator.gd"
)

var _fact_change_count: int = 0

func run_tests() -> int:
	_begin_test_run()
	_test_claim_and_round_trip()
	_test_condition_evaluation()
	_test_fact_action_without_quest_manager()
	_test_malformed_and_unknown_records()
	_test_save_manager_round_trip_and_legacy_save()
	_cleanup()
	return _finish_test_run("Dialogue state tests")

func _test_claim_and_round_trip() -> void:
	var state := DialogueState.new()
	state.fact_changed.connect(_on_fact_changed)
	_fact_change_count = 0
	_expect_true(state.claim_fact(&"rowan", &"introduction_seen"), "first durable fact claim succeeds")
	_expect_equal(state.claim_fact(&"rowan", &"introduction_seen"), false, "duplicate durable fact claim is rejected")
	_expect_equal(_fact_change_count, 1, "durable fact emits one change signal")
	var restored := DialogueState.new()
	restored.load_save_data(state.get_save_data())
	_expect_true(restored.has_fact(&"rowan", &"introduction_seen"), "durable fact survives a data round trip")
	_expect_equal(restored.has_fact(&"nessa", &"introduction_seen"), false, "facts remain scoped to a stable NPC ID")

func _test_condition_evaluation() -> void:
	var condition := DialogueCondition.new()
	condition.condition_id = &"dialogue_fact_set"
	condition.parameters[&"fact_id"] = &"introduction_seen"
	var evaluator := DialogueConditionEvaluator.new()
	var context: Dictionary[StringName, Variant] = {
		&"dialogue_facts": {&"introduction_seen": true},
	}
	_expect_true(evaluator.is_met(condition, context), "dialogue fact condition detects a claimed fact")
	condition.parameters[&"expected"] = false
	_expect_equal(evaluator.is_met(condition, context), false, "dialogue fact condition supports an expected false value")

func _test_fact_action_without_quest_manager() -> void:
	var state := DialogueState.new()
	var controller := NpcQuestDialogueController.new()
	controller.set_dialogue_state(state)
	var action := DialogueAction.new()
	action.action_id = &"set_dialogue_fact"
	action.parameters[&"fact_id"] = &"introduction_seen"
	var context: Dictionary[StringName, Variant] = {&"npc_id": &"rowan"}
	controller.handle_action(action, context)
	controller.handle_action(action, context)
	_expect_true(state.has_fact(&"rowan", &"introduction_seen"), "dialogue fact actions do not depend on quest state")
	controller.clear_dialogue_state()

func _test_malformed_and_unknown_records() -> void:
	var known_ids: Array[StringName] = [&"rowan", &"nessa"]
	var malformed: Dictionary = {
		"schema_version": 0,
		"data": {"npc_facts": {
			"rowan": ["met", "met", "", 7],
			"unknown_npc": ["met"],
			"nessa": "not an array",
		}},
	}
	var migrated := DIALOGUE_SAVE_MIGRATOR.migrate(malformed, known_ids, false)
	_expect_equal(migrated["schema_version"], DIALOGUE_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION, "legacy dialogue state migrates to the current schema")
	_expect_equal(migrated["data"]["npc_facts"], {"rowan": ["met"]}, "migration removes malformed, duplicate, and unknown facts")
	var malformed_document := DIALOGUE_SAVE_MIGRATOR.migrate(
		{"schema_version": 1, "data": []}, known_ids, false
	)
	_expect_equal(malformed_document["data"], {"npc_facts": {}}, "malformed dialogue documents recover as empty state")

func _test_save_manager_round_trip_and_legacy_save() -> void:
	_prepare_game_state()
	SaveManager.save_game()
	GameState.dialogue_state.claim_fact(&"rowan", &"introduction_seen")
	GameState.dialogue_state.clear()
	SaveManager.load_game(TEST_SAVE_SLOT)
	_expect_true(
		GameState.dialogue_state.has_fact(&"rowan", &"introduction_seen"),
		"new dialogue facts are persisted immediately"
	)
	var quest_document := SaveManager._load_json(TEST_SAVE_SLOT, "quests.json")
	_expect_equal(quest_document.get("data", {}).has("npc_facts"), false, "quest saves do not duplicate durable dialogue state")
	var dialogue_path := SaveManager.get_slot_dir(TEST_SAVE_SLOT).path_join("dialogue.json")
	DirAccess.remove_absolute(dialogue_path)
	GameState.dialogue_state.load_save_data({
		"npc_facts": {"rowan": ["stale_fact"]}
	})
	SaveManager.load_game(TEST_SAVE_SLOT)
	_expect_true(GameState.dialogue_state.get_facts(&"rowan").is_empty(), "older saves without dialogue.json load with empty dialogue state")

func _prepare_game_state() -> void:
	GameState.reset_state()
	GameState.hero = HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	GameState.hero.name = "Dialogue State Test Hero"
	GameState.village = Village.new()
	GameState.village.name = "Dialogue State Test Village"
	GameState.village.inn = Inn.new()
	GameState.village.potion_shop = Shop.new()
	GameState.village.weapon_shop = Shop.new()
	var manager := QuestManager.new()
	manager.new_game()
	GameState.set_quest_manager(manager)
	WorldManager.reset()
	SaveManager.save_slot = TEST_SAVE_SLOT

func _cleanup() -> void:
	GameState.reset_state()
	if SaveManager.has_save_data(TEST_SAVE_SLOT):
		SaveManager.delete_slot(TEST_SAVE_SLOT)

func _on_fact_changed(_npc_id: StringName, _fact_id: StringName) -> void:
	_fact_change_count += 1
