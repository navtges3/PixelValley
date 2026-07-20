extends Node


@onready var _effect_test_cases: Array[TestCase] = [
	$Effects/ActiveEffectTests,
	$Effects/EffectIntegrationTests,
	$Effects/EffectLifecycleEventTests,
]

@onready var _quest_test_cases: Array[TestCase] = [
	$Quests/QuestManagerMultiQuestTests,
	$Quests/QuestManagerLifecycleTests,
	$Quests/QuestSaveMigrationTests,
]

@onready var _reward_test_cases: Array[TestCase] = [
	$Rewards/RewardServiceTests,
]


func _ready() -> void:
	var total_failures: int = 0
	total_failures += _run_section("EFFECTS", _effect_test_cases)
	total_failures += _run_section("QUESTS", _quest_test_cases)
	total_failures += _run_section("REWARDS", _reward_test_cases)

	print("\n========== TEST SUMMARY ==========")
	if total_failures == 0:
		print("All test sections passed.")
	else:
		printerr("Test suite failed: %d total failures" % total_failures)
	get_tree().quit(0 if total_failures == 0 else 1)


func _run_section(section_name: String, test_cases: Array[TestCase]) -> int:
	print("\n========== %s TESTS ==========" % section_name)
	var section_failures: int = 0
	for test_case: TestCase in test_cases:
		section_failures += test_case.run_tests()

	if section_failures == 0:
		print("%s tests passed." % section_name.capitalize())
	else:
		printerr("%s tests failed: %d" % [section_name.capitalize(), section_failures])
	return section_failures
