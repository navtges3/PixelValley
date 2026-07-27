extends TestCase

var _visited_pages: Array[String] = []
var _response_counts: Array[int] = []
var _action_ids: Array[StringName] = []
var _finish_reasons: Array[int] = []
var _started_count: int = 0

func run_tests() -> int:
	_begin_test_run()
	_test_context_equals_condition()
	_test_authored_progression_conversations()
	_test_branching_conversation()
	_test_condition_skips_to_fallback()
	_test_actions_emit_once()
	_test_cancel_and_abort()
	_test_empty_pages_are_rejected()
	return _finish_test_run("DialogueRunner tests")

func _test_authored_progression_conversations() -> void:
	var paths: Array[String] = [
		"res://resources/dialogue/rowan_conversation.tres",
		"res://resources/dialogue/nessa_conversation.tres",
		"res://resources/dialogue/oren_conversation.tres",
	]
	var progression_states: Array[StringName] = [
		&"goblin_threat",
		&"orc_threat",
		&"ogre_threat",
		&"victory",
	]

	for path: String in paths:
		var conversation := load(path) as DialogueConversation
		_expect_not_null(conversation, "authored dialogue loads: %s" % path)
		if conversation == null:
			continue

		for progression_state: StringName in progression_states:
			_reset_signal_captures()
			var context: Dictionary[StringName, Variant] = {
				&"main_progression": progression_state,
			}
			var runner := _make_connected_runner()
			_expect_true(
				runner.start(conversation, context),
				"authored dialogue starts for '%s': %s"
					% [progression_state, path]
			)
			_expect_equal(
				_visited_pages,
				["%s:0" % progression_state],
				"authored dialogue selects '%s': %s"
					% [progression_state, path]
			)
			runner.abort()

func _test_context_equals_condition() -> void:
	var condition := _make_context_condition(
		&"location_id",
		&"village"
	)
	var conditions: Array[DialogueCondition] = [condition]
	var evaluator := DialogueConditionEvaluator.new()
	var village_context: Dictionary[StringName, Variant] = {
		&"location_id": &"village",
	}
	var forest_context: Dictionary[StringName, Variant] = {
		&"location_id": &"forest",
	}

	_expect_true(
		evaluator.are_met(conditions, village_context),
		"context_equals passes for the expected value"
	)
	_expect_equal(
		evaluator.are_met(conditions, forest_context),
		false,
		"context_equals fails for a different value"
	)

func _test_branching_conversation() -> void:
	_reset_signal_captures()
	var welcome := _make_entry(
		&"welcome",
		["Welcome.", "What would you like to know?"]
	)
	var info := _make_entry(&"info", ["Here is the information."])
	var goodbye := _make_entry(&"goodbye", ["Until next time."])

	var ask_response := DialogueResponse.new()
	ask_response.text = "Tell me more."
	ask_response.next_entry_id = &"info"
	var leave_response := DialogueResponse.new()
	leave_response.text = "Goodbye."
	leave_response.next_entry_id = &"goodbye"
	welcome.responses.append(ask_response)
	welcome.responses.append(leave_response)

	var runner := _make_connected_runner()
	var conversation := _make_conversation(
		[welcome, info, goodbye],
		&"welcome"
	)

	_expect_true(
		runner.start(conversation),
		"branching conversation starts"
	)
	runner.advance()
	runner.advance()

	_expect_equal(
		_response_counts,
		[2],
		"last page exposes both authored responses"
	)

	runner.choose_response(0)
	runner.advance()

	_expect_equal(
		_visited_pages,
		["welcome:0", "welcome:1", "info:0"],
		"selected response follows its branch"
	)
	_expect_equal(
		_finish_reasons,
		[DialogueRunner.FinishReason.COMPLETED],
		"branch completes normally"
	)

func _test_condition_skips_to_fallback() -> void:
	_reset_signal_captures()
	var conditional := _make_entry(
		&"conditional",
		["Only shown in the village."]
	)
	conditional.conditions.append(
		_make_context_condition(&"location_id", &"village")
	)
	conditional.skip_entry_id = &"fallback"
	var fallback := _make_entry(
		&"fallback",
		["Shown outside the village."]
	)
	var conversation := _make_conversation(
		[conditional, fallback],
		&"conditional"
	)
	var context: Dictionary[StringName, Variant] = {
		&"location_id": &"forest",
	}
	var runner := _make_connected_runner()

	_expect_true(
		runner.start(conversation, context),
		"conditional conversation starts"
	)
	_expect_equal(
		_visited_pages,
		["fallback:0"],
		"failed condition follows skip_entry_id"
	)

func _test_actions_emit_once() -> void:
	_reset_signal_captures()
	var entry := _make_entry(&"start", ["Choose an action."])
	var entry_action := DialogueAction.new()
	entry_action.action_id = &"entry_action"
	entry.actions.append(entry_action)

	var response := DialogueResponse.new()
	response.text = "Continue."
	var response_action := DialogueAction.new()
	response_action.action_id = &"response_action"
	response.actions.append(response_action)
	entry.responses.append(response)

	var runner := _make_connected_runner()
	var conversation := _make_conversation([entry], &"start")
	runner.start(conversation)
	runner.advance()
	runner.choose_response(0)

	_expect_equal(
		_action_ids,
		[&"entry_action", &"response_action"],
		"entry and response actions each emit once"
	)

func _test_cancel_and_abort() -> void:
	_reset_signal_captures()
	var entry := _make_entry(&"start", ["Cannot be cancelled."])
	var conversation := _make_conversation([entry], &"start", false)
	var runner := _make_connected_runner()
	runner.start(conversation)

	runner.cancel()
	_expect_true(
		runner.is_running(),
		"cancel respects can_cancel"
	)

	runner.abort()
	_expect_equal(
		runner.is_running(),
		false,
		"abort always stops the conversation"
	)
	_expect_equal(
		_finish_reasons,
		[DialogueRunner.FinishReason.INTERRUPTED],
		"abort emits the interrupted reason"
	)

func _test_empty_pages_are_rejected() -> void:
	_reset_signal_captures()
	var invalid_entry := _make_entry(&"start", [])
	var conversation := _make_conversation(
		[invalid_entry],
		&"start"
	)
	var runner := _make_connected_runner()
	var validation_errors := runner.get_validation_errors(conversation)

	_expect_equal(
		validation_errors.size(),
		1,
		"entry with no pages produces one validation error"
	)
	_expect_contains(
		validation_errors[0],
		"has no pages",
		"empty page validation identifies the invalid entry"
	)
	_expect_equal(
		runner.is_running(),
		false,
		"validation does not retain runner state"
	)

func _make_context_condition(
	key: StringName,
	value: Variant
) -> DialogueCondition:
	var condition := DialogueCondition.new()
	condition.condition_id = &"context_equals"
	condition.parameters[&"key"] = key
	condition.parameters[&"value"] = value
	return condition

func _make_entry(
	identity: StringName,
	pages: Array[String]
) -> DialogueEntry:
	var entry := DialogueEntry.new()
	entry.entry_id = identity
	entry.pages = pages
	return entry

func _make_conversation(
	entries: Array[DialogueEntry],
	start_entry_id: StringName,
	can_cancel: bool = true
) -> DialogueConversation:
	var conversation := DialogueConversation.new()
	conversation.conversation_id = &"test_conversation"
	conversation.start_entry_id = start_entry_id
	conversation.can_cancel = can_cancel
	conversation.entries = entries
	return conversation

func _make_connected_runner() -> DialogueRunner:
	var runner := DialogueRunner.new()
	runner.conversation_started.connect(_on_conversation_started)
	runner.line_changed.connect(_on_line_changed)
	runner.responses_changed.connect(_on_responses_changed)
	runner.action_requested.connect(_on_action_requested)
	runner.conversation_finished.connect(_on_conversation_finished)
	return runner

func _reset_signal_captures() -> void:
	_visited_pages.clear()
	_response_counts.clear()
	_action_ids.clear()
	_finish_reasons.clear()
	_started_count = 0

func _on_conversation_started(
	_conversation: DialogueConversation
) -> void:
	_started_count += 1

func _on_line_changed(
	entry: DialogueEntry,
	page_index: int
) -> void:
	_visited_pages.append("%s:%d" % [entry.entry_id, page_index])

func _on_responses_changed(
	responses: Array[DialogueResponse]
) -> void:
	_response_counts.append(responses.size())

func _on_action_requested(
	action: DialogueAction,
	_context: Dictionary[StringName, Variant]
) -> void:
	_action_ids.append(action.action_id)

func _on_conversation_finished(
	reason: DialogueRunner.FinishReason
) -> void:
	_finish_reasons.append(reason)
