extends Node
class_name TestCase


var _failures: int = 0


func _ready() -> void:
	if get_tree().current_scene == self:
		get_tree().quit(run_tests())


func run_tests() -> int:
	push_error("TestCase.run_tests() must be overridden.")
	return 1


func _begin_test_run() -> void:
	_failures = 0


func _finish_test_run(suite_name: String) -> int:
	if _failures == 0:
		print("%s passed." % suite_name)
	else:
		printerr("%s failed: %d" % [suite_name, _failures])
	return _failures


func _expect_not_null(value: Variant, message: String) -> void:
	if value != null:
		return
	_failures += 1
	printerr("FAIL: %s (value was null)" % message)


func _expect_true(value: bool, message: String) -> void:
	if value:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _expect_contains(actual: String, expected: String, message: String) -> void:
	if actual.to_lower().contains(expected.to_lower()):
		return
	_failures += 1
	printerr(
		'FAIL: %s (expected "%s" in "%s")'
		% [message, expected, actual]
	)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failures += 1
	printerr(
		"FAIL: %s (expected %s, got %s)"
		% [message, expected, actual]
	)
