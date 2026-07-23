extends TestCase

const QUEST_SAVE_MIGRATOR := preload("res://scripts/save/quest_save_migrator.gd")


func run_tests() -> int:
	_begin_test_run()
	_test_legacy_save_migrates_with_safe_defaults()
	_test_malformed_legacy_available_list_recovers()
	_test_current_save_preserves_all_quest_state()
	_test_tracking_state_round_trip()
	_test_tracking_state_defaults_and_validation()
	_test_unknown_objective_state_is_preserved_generically()
	_test_malformed_records_are_skipped_safely()
	_test_newer_schema_recovers_recognized_fields()
	return _finish_test_run("Quest save migration tests")


func _test_malformed_legacy_available_list_recovers() -> void:
	var malformed_document := {
		"schema_version": 1,
		"data": {
			"available_quests": "not an array",
		}
	}
	var migrated: Dictionary = QUEST_SAVE_MIGRATOR.migrate(malformed_document, [], false)
	var data: Dictionary = migrated["data"]

	_expect_equal(
		migrated["schema_version"],
		QUEST_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION,
		"malformed schema 1 saves still migrate to the current schema"
	)
	_expect_equal(data["active_quests"], [], "malformed legacy available quests recover as empty")


func _test_legacy_save_migrates_with_safe_defaults() -> void:
	var legacy_document := {
		"data": {
			"available_quests": [{
				"id": 1,
				"title": "Legacy Progress",
				"description": "Created before quest save versioning.",
				"completed": false,
				"objectives": [{
					"monster_id": MonsterLoader.MonsterID.GOBLIN,
					"target_amount": 5,
					"current_amount": 3,
				}],
				"reward": {"experience": 25, "gold": 10},
			}],
		}
	}
	var migrated: Dictionary = QUEST_SAVE_MIGRATOR.migrate(legacy_document, [1])
	var data: Dictionary = migrated["data"]
	var quest: Dictionary = data["active_quests"][0]
	var objective: Dictionary = quest["objectives"][0]
	var loaded_manager: QuestManager = SaveManager._load_quests(data)
	var loaded_quest: Quest = loaded_manager.get_quest_by_id(1)

	_expect_equal(migrated["schema_version"], QUEST_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION, "legacy saves migrate to the current schema")
	_expect_equal(data["locked_quests"], [], "legacy saves default missing locked quests to an empty list")
	_expect_equal(data["offered_quests"], [], "legacy saves default missing offered quests to an empty list")
	_expect_equal(data["ready_quests"], [], "legacy saves default missing ready quests to an empty list")
	_expect_equal(data["completed_quests"], [], "legacy saves default missing completed quests to an empty list")
	_expect_equal(quest["category"], Quest.Category.MAIN, "legacy quests default to the main category")
	_expect_equal(quest["source_type"], Quest.SourceType.AUTOMATIC, "legacy quests default to automatic activation")
	_expect_equal(quest["source_id"], "", "legacy quests default to an empty source ID")
	_expect_equal(objective["type"], "kill", "legacy objectives default to the kill objective type")
	_expect_equal(objective["current_amount"], 3, "legacy objective progress is preserved")
	_expect_equal(quest["reward"]["experience"], 25, "legacy experience rewards are preserved")
	_expect_equal(quest["reward"]["gold"], 10, "legacy gold rewards are preserved")
	_expect_not_null(loaded_quest, "migrated legacy records construct a runtime quest")
	var loaded_objective := loaded_quest.objectives[0] as KillQuestObjective
	_expect_not_null(loaded_objective, "legacy kill data constructs a kill objective")
	if loaded_objective != null:
		_expect_equal(loaded_objective.current_amount, 3, "runtime loading keeps migrated legacy progress")


func _test_current_save_preserves_all_quest_state() -> void:
	var current_document := {
		"schema_version": QUEST_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION,
		"data": {
			"locked_quests": [],
			"offered_quests": [],
			"active_quests": [],
			"ready_quests": [],
			"completed_quests": [{
				"id": 9001,
				"title": "Embedded Quest",
				"description": "Unknown locally but complete in the save.",
				"category": Quest.Category.SIDE,
				"source_type": Quest.SourceType.NPC,
				"source_id": "npc_scout",
				"next_quests": [9002],
				"unlocks_locations": ["hidden_path"],
				"completed": true,
				"final_quest": false,
				"objectives": [{
					"type": "kill",
					"monster_id": MonsterLoader.MonsterID.ORC,
					"target_amount": 2,
					"current_amount": 2,
					"location_id": "orc_war_camp",
				}],
				"reward": {
					"experience": 50,
					"gold": 20,
					"items": ["health_potion"],
					"random_weapon": true,
					"rarity": Item.Rarity.RARE,
				},
			}],
		}
	}
	var migrated: Dictionary = QUEST_SAVE_MIGRATOR.migrate(current_document, [1], false)
	var quest: Dictionary = migrated["data"]["completed_quests"][0]

	_expect_equal(quest["id"], 9001, "unknown quest IDs retain their embedded save record")
	_expect_equal(quest["completed"], true, "completion state is preserved")
	_expect_equal(quest["category"], Quest.Category.SIDE, "category is preserved")
	_expect_equal(quest["source_type"], Quest.SourceType.NPC, "source type is preserved")
	_expect_equal(quest["source_id"], "npc_scout", "source ID is preserved")
	_expect_equal(quest["next_quests"], [9002], "follow-up quest unlocks are preserved")
	_expect_equal(quest["unlocks_locations"], ["hidden_path"], "location unlocks are preserved")
	_expect_equal(quest["objectives"][0]["current_amount"], 2, "current objective progress is preserved")
	_expect_equal(quest["reward"]["items"], ["health_potion"], "item rewards are preserved")
	_expect_equal(quest["reward"]["random_weapon"], true, "random weapon rewards are preserved")


func _test_tracking_state_round_trip() -> void:
	var manager := QuestManager.new()
	var active_quest := _make_saved_quest(9101)
	manager.active_quests.append(active_quest)
	manager.track_quest(active_quest.id)

	var saved_data: Dictionary = SaveManager._get_quests_data(manager)
	var loaded_manager: QuestManager = SaveManager._load_quests(saved_data)
	var loaded_quest: Quest = loaded_manager.get_tracked_quest()

	_expect_equal(saved_data["tracked_quest_id"], active_quest.id, "quest saves store the tracked quest ID")
	_expect_equal(loaded_manager.tracked_quest_id, active_quest.id, "loading restores a valid tracked quest ID")
	_expect_not_null(loaded_quest, "a restored tracked quest resolves to a runtime quest")
	if loaded_quest != null:
		_expect_equal(loaded_quest.id, active_quest.id, "the restored tracked quest keeps its stable ID")


func _test_tracking_state_defaults_and_validation() -> void:
	var active_quest := _make_saved_quest(9102)
	var active_record: Dictionary = SaveManager._get_quest_data(active_quest)
	var legacy_manager: QuestManager = SaveManager._load_quests({
		"active_quests": [active_record],
	})
	_expect_equal(legacy_manager.tracked_quest_id, -1, "older saves default to no tracked quest")

	var unknown_manager: QuestManager = SaveManager._load_quests({
		"tracked_quest_id": 9999,
		"active_quests": [active_record],
	})
	_expect_equal(unknown_manager.tracked_quest_id, -1, "unknown saved tracking IDs are discarded")

	var offered_manager: QuestManager = SaveManager._load_quests({
		"tracked_quest_id": active_quest.id,
		"offered_quests": [active_record],
	})
	_expect_equal(offered_manager.tracked_quest_id, -1, "offered quests are not restored as tracked")

	var ready_manager: QuestManager = SaveManager._load_quests({
		"tracked_quest_id": active_quest.id,
		"ready_quests": [active_record],
	})
	_expect_equal(ready_manager.tracked_quest_id, active_quest.id, "ready quests restore as tracked")


func _make_saved_quest(quest_id: int) -> Quest:
	var objective := KillQuestObjective.new()
	objective.monster_id = MonsterLoader.MonsterID.GOBLIN
	objective.target_amount = 3
	objective.current_amount = 1
	objective.location_id = "forest"
	var quest := Quest.new()
	quest.id = quest_id
	quest.title = "Saved Quest %d" % quest_id
	quest.description = "Tracking persistence test quest."
	quest.category = Quest.Category.SIDE
	quest.source_type = Quest.SourceType.QUEST_BOARD
	quest.source_id = "test_board"
	quest.objectives.append(objective)
	return quest


func _test_unknown_objective_state_is_preserved_generically() -> void:
	var document := {
		"schema_version": QUEST_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION,
		"data": {
			"active_quests": [{
				"id": 1,
				"objectives": [{
					"type": "collect",
					"item_id": "healing_herb",
					"required_amount": 4,
					"collected_amount": 2,
				}],
			}],
		},
	}
	var migrated: Dictionary = QUEST_SAVE_MIGRATOR.migrate(document, [1], false)
	var objective: Dictionary = migrated["data"]["active_quests"][0]["objectives"][0]

	_expect_equal(objective["type"], "collect", "normalization preserves an objective type discriminator")
	_expect_equal(objective["item_id"], "healing_herb", "normalization preserves objective-specific fields")
	_expect_equal(objective["collected_amount"], 2, "normalization preserves objective-specific progress")
	_expect_true(
		not objective.has("monster_id"),
		"normalization does not add kill-only state to another objective type"
	)


func _test_malformed_records_are_skipped_safely() -> void:
	var malformed_document := {
		"data": {
			"locked_quests": "not an array",
			"available_quests": ["not a quest", {"id": 0}, {"id": 1, "objectives": [null], "reward": "bad"}],
			"completed_quests": [{"id": 1}],
		}
	}
	var migrated: Dictionary = QUEST_SAVE_MIGRATOR.migrate(malformed_document, [1], false)
	var data: Dictionary = migrated["data"]

	_expect_equal(data["locked_quests"].size(), 0, "malformed quest lists recover as empty")
	_expect_equal(data["active_quests"].size(), 1, "only a valid active quest record is retained")
	_expect_equal(data["completed_quests"].size(), 0, "duplicate quest IDs are skipped across lifecycle lists")
	_expect_equal(data["active_quests"][0]["objectives"], [], "malformed objectives are skipped")
	_expect_equal(data["active_quests"][0]["reward"]["gold"], 0, "malformed rewards use safe defaults")


func _test_newer_schema_recovers_recognized_fields() -> void:
	var future_document := {
		"schema_version": QUEST_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION + 1,
		"data": {
			"active_quests": [{"id": 1, "title": "Future Quest"}],
		}
	}
	var migrated: Dictionary = QUEST_SAVE_MIGRATOR.migrate(future_document, [1], false)

	_expect_equal(migrated["schema_version"], QUEST_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION + 1, "newer schema markers are not silently downgraded")
	_expect_equal(migrated["data"]["active_quests"][0]["title"], "Future Quest", "recognized data from a newer schema remains loadable")
