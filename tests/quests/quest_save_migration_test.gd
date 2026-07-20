extends TestCase

const QUEST_SAVE_MIGRATOR := preload("res://scripts/save/quest_save_migrator.gd")


func run_tests() -> int:
	_begin_test_run()
	_test_legacy_save_migrates_with_safe_defaults()
	_test_current_save_preserves_all_quest_state()
	_test_malformed_records_are_skipped_safely()
	_test_newer_schema_recovers_recognized_fields()
	return _finish_test_run("Quest save migration tests")


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
	var quest: Dictionary = data["available_quests"][0]
	var objective: Dictionary = quest["objectives"][0]
	var loaded_manager: QuestManager = SaveManager._load_quests(data)
	var loaded_quest: Quest = loaded_manager.get_quest_by_id(1)

	_expect_equal(migrated["schema_version"], QUEST_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION, "legacy saves migrate to the current schema")
	_expect_equal(data["locked_quests"], [], "legacy saves default missing locked quests to an empty list")
	_expect_equal(data["completed_quests"], [], "legacy saves default missing completed quests to an empty list")
	_expect_equal(quest["category"], Quest.Category.MAIN, "legacy quests default to the main category")
	_expect_equal(quest["source_type"], Quest.SourceType.AUTOMATIC, "legacy quests default to automatic activation")
	_expect_equal(quest["source_id"], "", "legacy quests default to an empty source ID")
	_expect_equal(objective["type"], "kill", "legacy objectives default to the kill objective type")
	_expect_equal(objective["current_amount"], 3, "legacy objective progress is preserved")
	_expect_equal(quest["reward"]["experience"], 25, "legacy experience rewards are preserved")
	_expect_equal(quest["reward"]["gold"], 10, "legacy gold rewards are preserved")
	_expect_not_null(loaded_quest, "migrated legacy records construct a runtime quest")
	_expect_equal(loaded_quest.get_slain_count(), 3, "runtime loading keeps migrated legacy progress")


func _test_current_save_preserves_all_quest_state() -> void:
	var current_document := {
		"schema_version": QUEST_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION,
		"data": {
			"locked_quests": [],
			"available_quests": [],
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
	_expect_equal(data["available_quests"].size(), 1, "only a valid quest record is retained")
	_expect_equal(data["completed_quests"].size(), 0, "duplicate quest IDs are skipped across lifecycle lists")
	_expect_equal(data["available_quests"][0]["objectives"], [], "malformed objectives are skipped")
	_expect_equal(data["available_quests"][0]["reward"]["gold"], 0, "malformed rewards use safe defaults")


func _test_newer_schema_recovers_recognized_fields() -> void:
	var future_document := {
		"schema_version": QUEST_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION + 1,
		"data": {
			"available_quests": [{"id": 1, "title": "Future Quest"}],
		}
	}
	var migrated: Dictionary = QUEST_SAVE_MIGRATOR.migrate(future_document, [1], false)

	_expect_equal(migrated["schema_version"], QUEST_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION + 1, "newer schema markers are not silently downgraded")
	_expect_equal(migrated["data"]["available_quests"][0]["title"], "Future Quest", "recognized data from a newer schema remains loadable")
