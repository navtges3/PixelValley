extends Node


@onready var _test_cases: Array[TestCase] = [
	$ActiveEffectTests,
	$EffectIntegrationTests,
	$EffectLifecycleEventTests,
]


func _ready() -> void:
	var total_failures: int = 0
	for test_case: TestCase in _test_cases:
		total_failures += test_case.run_tests()

	if total_failures == 0:
		print("All test suites passed.")
	else:
		printerr("Test suite failed: %d total failures" % total_failures)
	get_tree().quit(0 if total_failures == 0 else 1)
