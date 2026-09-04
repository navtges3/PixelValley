extends TestCase

var _visited_pages: Array[String] = []
var _response_counts: Array[int] = []
var _action_ids: Array[StringName] = []
var _finish_reasons: Array[int] = []
var _started_count: int = 0

func run_tests() -> int:
	_begin_test_run()
	_test_context_equals_condition()
	_test_authored_progression_sequences()
	_test_branching_conversation()
	_test_condition_skips_to_fallback()
	_test_actions_emit_once()
	_test_duplicate_response_input_is_idempotent()
	_test_advance_does_not_bypass_responses()
	_test_cancel_and_abort()
	_test_empty_pages_are_rejected()
	_test_unknown_entry_id_is_rejected()
	_test_sequence_state_selection()
	_test_ambient_sequence_execution()
	_test_sequence_cancel_and_abort()
	_test_sequence_validation_errors()
	return _finish_test_run("DialogueRunner tests")

func _test_authored_progression_sequences() -> void:
	var paths: Array[String] = [
		"res://resources/dialogue/sequences/rowan_ambient.tres",
		"res://resources/dialogue/sequences/nessa_ambient.tres",
		"res://resources/dialogue/sequences/oren_ambient.tres",
	]
	var progression_states: Array[StringName] = [
		&"goblin_threat",
		&"orc_threat",
		&"ogre_threat",
		&"victory",
	]

	for path: String in paths:
		var sequence := load(path) as DialogueSequence
		_expect_not_null(sequence, "authored dialogue sequence loads: %s" % path)
		if sequence == null:
			continue

		for progression_state: StringName in progression_states:
			_reset_signal_captures()
			var context: Dictionary[StringName, Variant] = {
				&"main_progression": progression_state,
			}
			var runner := _make_connected_runner()
			_expect_true(
				runner.start_sequence(sequence, context),
				"authored dialogue sequence starts for '%s': %s"
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
	var sequence := _make_sequence(
		[welcome, info, goodbye],
		&"welcome"
	)

	_expect_true(
		runner.start_sequence(sequence, {}),
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
	var sequence := _make_sequence(
		[conditional, fallback],
		&"conditional"
	)
	var context: Dictionary[StringName, Variant] = {
		&"location_id": &"forest",
	}
	var runner := _make_connected_runner()

	_expect_true(
		runner.start_sequence(sequence, context),
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
	var sequence := _make_sequence([entry], &"start")
	runner.start_sequence(sequence, {})
	runner.advance()
	runner.choose_response(0)

	_expect_equal(
		_action_ids,
		[&"entry_action", &"response_action"],
		"entry and response actions each emit once"
	)

func _test_duplicate_response_input_is_idempotent() -> void:
	_reset_signal_captures()
	var entry := _make_entry(&"start", ["Choose once."])
	var response := DialogueResponse.new()
	response.text = "Continue."
	var action := DialogueAction.new()
	action.action_id = &"one_shot"
	response.actions.append(action)
	entry.responses.append(response)
	var runner := _make_connected_runner()
	runner.action_requested.connect(
		func(
			_action: DialogueAction,
			_context: Dictionary[StringName, Variant]
		) -> void:
			runner.choose_response(0)
	)
	runner.start_sequence(_make_sequence([entry], &"start"), {})
	runner.advance()
	runner.choose_response(0)
	runner.choose_response(0)
	_expect_equal(
		_action_ids,
		[&"one_shot"],
		"rapid and reentrant response input emits its action once"
	)

func _test_advance_does_not_bypass_responses() -> void:
	_reset_signal_captures()
	var entry := _make_entry(&"start", ["Choose a response."])
	var response := DialogueResponse.new()
	response.text = "Required choice."
	entry.responses.append(response)
	var runner := _make_connected_runner()
	runner.start_sequence(_make_sequence([entry], &"start"), {})
	runner.advance()
	runner.advance()
	_expect_true(
		runner.is_running(),
		"advance input cannot bypass a required response"
	)
	_expect_equal(
		_response_counts,
		[1],
		"rapid advance does not expose responses repeatedly"
	)

func _test_cancel_and_abort() -> void:
	_reset_signal_captures()
	var entry := _make_entry(&"start", ["Cannot be cancelled."])
	var sequence := _make_sequence([entry], &"start", false)
	var runner := _make_connected_runner()
	runner.start_sequence(sequence, {})

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
	var sequence := _make_sequence(
		[invalid_entry],
		&"start"
	)
	var runner := _make_connected_runner()
	var validation_errors := runner.get_sequence_validation_errors(sequence)

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

func _test_unknown_entry_id_is_rejected() -> void:
	var entry := _make_entry(&"known", ["Known entry."])
	var sequence := _make_sequence([entry], &"missing")
	var runner := DialogueRunner.new()
	var errors := runner.get_sequence_validation_errors(sequence)
	_expect_equal(errors.size(), 1, "unknown start entry produces one validation error")
	_expect_contains(errors[0], "was not found", "unknown entry error identifies the missing ID")
	_expect_equal(runner.is_running(), false, "unknown entry validation does not trap the runner")

func _test_sequence_state_selection() -> void:
	var offered_entry := _make_entry(&"entry_offered", ["I have a task for you."])
	var active_entry := _make_entry(&"entry_active", ["How goes the task?"])
	var ready_entry := _make_entry(&"entry_ready", ["You completed it!"])
	var completed_entry := _make_entry(&"entry_completed", ["Thanks again."])
	var locked_entry := _make_entry(&"entry_locked", ["Not ready yet."])
	var default_entry := _make_entry(&"entry_default", ["Greetings traveler."])

	var sequence := DialogueSequence.new()
	sequence.sequence_id = &"quest_seq_1020"
	sequence.quest_id = 1020
	sequence.priority = 10
	sequence.start_entry_id = &"entry_default"
	sequence.entries = [offered_entry, active_entry, ready_entry, completed_entry, locked_entry, default_entry]
	sequence.state_entries = {
		&"offered": &"entry_offered",
		&"active": &"entry_active",
		&"ready": &"entry_ready",
		&"completed": &"entry_completed",
		&"locked": &"entry_locked",
	}

	_expect_equal(sequence.get_entry(&"entry_offered"), offered_entry, "get_entry returns the matching entry")
	_expect_null(sequence.get_entry(&"missing_entry"), "get_entry returns null for unknown entry")

	_expect_true(sequence.has_state(QuestManager.LifecycleState.OFFERED), "has_state returns true for offered")
	_expect_true(sequence.has_state(QuestManager.LifecycleState.ACTIVE), "has_state returns true for active")
	_expect_true(sequence.has_state(QuestManager.LifecycleState.READY), "has_state returns true for ready")
	_expect_true(sequence.has_state(QuestManager.LifecycleState.COMPLETED), "has_state returns true for completed")
	_expect_true(sequence.has_state(QuestManager.LifecycleState.LOCKED), "has_state returns true for locked")

	var states: Array[StringName] = [&"offered", &"active", &"ready", &"completed", &"locked"]
	for state_name: StringName in states:
		_reset_signal_captures()
		var runner := _make_connected_runner()
		var context: Dictionary[StringName, Variant] = {
			&"quest_id": 1020,
			&"quest_state": state_name,
		}
		_expect_true(
			runner.start_sequence(sequence, context),
			"sequence starts for state '%s'" % state_name
		)
		_expect_equal(
			_visited_pages,
			["entry_%s:0" % state_name],
			"sequence selects 'entry_%s' for state '%s'" % [state_name, state_name]
		)
		runner.abort()

	_reset_signal_captures()
	var fallback_runner := _make_connected_runner()
	var fallback_context: Dictionary[StringName, Variant] = {
		&"quest_id": 1020,
		&"quest_state": &"unknown_state",
	}
	_expect_true(fallback_runner.start_sequence(sequence, fallback_context), "sequence starts with fallback entry")
	_expect_equal(_visited_pages, ["entry_default:0"], "unmapped state falls back to start_entry_id")
	fallback_runner.abort()

func _test_ambient_sequence_execution() -> void:
	_reset_signal_captures()
	var start_entry := _make_entry(&"start", ["Hello.", "Need anything?"])
	var bye_entry := _make_entry(&"bye", ["Farewell."])

	var bye_response := DialogueResponse.new()
	bye_response.text = "Goodbye."
	bye_response.next_entry_id = &"bye"
	var bye_action := DialogueAction.new()
	bye_action.action_id = &"farewell_action"
	bye_response.actions.append(bye_action)
	start_entry.responses.append(bye_response)

	var sequence := DialogueSequence.new()
	sequence.sequence_id = &"ambient_seq"
	sequence.quest_id = -1
	sequence.start_entry_id = &"start"
	sequence.entries = [start_entry, bye_entry]

	var runner := _make_connected_runner()
	_expect_true(runner.start_sequence(sequence, {}), "ambient sequence starts")
	runner.advance()
	runner.advance()
	_expect_equal(_response_counts, [1], "responses presented")
	runner.choose_response(0)
	runner.advance()

	_expect_equal(
		_visited_pages,
		["start:0", "start:1", "bye:0"],
		"ambient sequence visits expected pages"
	)
	_expect_equal(_action_ids, [&"farewell_action"], "sequence response action emits")
	_expect_equal(_finish_reasons, [DialogueRunner.FinishReason.COMPLETED], "sequence completes normally")

func _test_sequence_cancel_and_abort() -> void:
	_reset_signal_captures()
	var uncancelable_entry := _make_entry(&"start", ["Cannot cancel."])
	var uncancelable_seq := DialogueSequence.new()
	uncancelable_seq.sequence_id = &"uncancelable_seq"
	uncancelable_seq.start_entry_id = &"start"
	uncancelable_seq.can_cancel = false
	uncancelable_seq.entries = [uncancelable_entry]

	var runner := _make_connected_runner()
	runner.start_sequence(uncancelable_seq, {})
	runner.cancel()
	_expect_true(runner.is_running(), "uncancelable sequence stays running on cancel()")
	runner.abort()
	_expect_equal(runner.is_running(), false, "abort() terminates sequence")
	_expect_equal(_finish_reasons, [DialogueRunner.FinishReason.INTERRUPTED], "abort emits INTERRUPTED")

	_reset_signal_captures()
	var cancelable_entry := _make_entry(&"start", ["Can cancel."])
	var cancelable_seq := DialogueSequence.new()
	cancelable_seq.sequence_id = &"cancelable_seq"
	cancelable_seq.start_entry_id = &"start"
	cancelable_seq.can_cancel = true
	cancelable_seq.entries = [cancelable_entry]

	var cancel_runner := _make_connected_runner()
	cancel_runner.start_sequence(cancelable_seq, {})
	cancel_runner.cancel()
	_expect_equal(cancel_runner.is_running(), false, "cancelable sequence stops on cancel()")
	_expect_equal(_finish_reasons, [DialogueRunner.FinishReason.CANCELLED], "cancel emits CANCELLED")

func _test_sequence_validation_errors() -> void:
	var runner := DialogueRunner.new()

	var null_errors := runner.get_sequence_validation_errors(null)
	_expect_equal(null_errors.size(), 1, "null sequence produces 1 error")

	var empty_id_seq := DialogueSequence.new()
	var id_errors := runner.get_sequence_validation_errors(empty_id_seq)
	_expect_contains(id_errors[0], "has no ID", "empty sequence ID is rejected")

	var empty_entries_seq := DialogueSequence.new()
	empty_entries_seq.sequence_id = &"seq_no_entries"
	var entry_errors := runner.get_sequence_validation_errors(empty_entries_seq)
	_expect_contains(entry_errors[0], "has no entries", "sequence with no entries is rejected")

	var ambient_no_start := DialogueSequence.new()
	ambient_no_start.sequence_id = &"ambient_no_start"
	ambient_no_start.entries = [_make_entry(&"entry1", ["Page"])]
	var ambient_errors := runner.get_sequence_validation_errors(ambient_no_start)
	_expect_contains(ambient_errors[0], "has no start entry", "ambient sequence with no start entry is rejected")

	var ambient_bad_start := DialogueSequence.new()
	ambient_bad_start.sequence_id = &"ambient_bad_start"
	ambient_bad_start.start_entry_id = &"missing"
	ambient_bad_start.entries = [_make_entry(&"entry1", ["Page"])]
	var ambient_bad_errors := runner.get_sequence_validation_errors(ambient_bad_start)
	_expect_contains(ambient_bad_errors[0], "was not found", "ambient sequence with missing start entry is rejected")

	var quest_bad_state := DialogueSequence.new()
	quest_bad_state.sequence_id = &"quest_bad_state"
	quest_bad_state.quest_id = 1010
	quest_bad_state.state_entries = {&"offered": &"missing_entry"}
	quest_bad_state.entries = [_make_entry(&"known_entry", ["Page"])]
	var quest_state_errors := runner.get_sequence_validation_errors(quest_bad_state)
	_expect_contains(quest_state_errors[0], "points to missing entry", "quest sequence with missing state entry target is rejected")

	var valid_seq := DialogueSequence.new()
	valid_seq.sequence_id = &"valid_seq"
	valid_seq.quest_id = 1010
	valid_seq.state_entries = {&"offered": &"known_entry"}
	valid_seq.entries = [_make_entry(&"known_entry", ["Page"])]
	var valid_errors := runner.get_sequence_validation_errors(valid_seq)
	_expect_equal(valid_errors.size(), 0, "valid sequence produces no errors")

func _make_context_condition(key: StringName, value: Variant) -> DialogueCondition:
	var condition := DialogueCondition.new()
	condition.condition_id = &"context_equals"
	condition.parameters[&"key"] = key
	condition.parameters[&"value"] = value
	return condition

func _make_entry(identity: StringName, pages: Array[String]) -> DialogueEntry:
	var entry := DialogueEntry.new()
	entry.entry_id = identity
	entry.pages = pages
	return entry

func _make_sequence(
	entries: Array[DialogueEntry],
	start_entry_id: StringName,
	can_cancel: bool = true
) -> DialogueSequence:
	var sequence := DialogueSequence.new()
	sequence.sequence_id = &"test_sequence"
	sequence.start_entry_id = start_entry_id
	sequence.can_cancel = can_cancel
	sequence.entries = entries
	return sequence

func _make_connected_runner() -> DialogueRunner:
	var runner := DialogueRunner.new()
	runner.sequence_started.connect(_on_sequence_started)
	runner.line_changed.connect(_on_line_changed)
	runner.responses_changed.connect(_on_responses_changed)
	runner.action_requested.connect(_on_action_requested)
	runner.dialogue_finished.connect(_on_dialogue_finished)
	return runner

func _reset_signal_captures() -> void:
	_visited_pages.clear()
	_response_counts.clear()
	_action_ids.clear()
	_finish_reasons.clear()
	_started_count = 0

func _on_sequence_started(_sequence: DialogueSequence) -> void:
	_started_count += 1

func _on_line_changed(entry: DialogueEntry, page_index: int) -> void:
	_visited_pages.append("%s:%d" % [entry.entry_id, page_index])

func _on_responses_changed(responses: Array[DialogueResponse]) -> void:
	_response_counts.append(responses.size())

func _on_action_requested(action: DialogueAction, _context: Dictionary[StringName, Variant]) -> void:
	_action_ids.append(action.action_id)

func _on_dialogue_finished(reason: DialogueRunner.FinishReason) -> void:
	_finish_reasons.append(reason)
