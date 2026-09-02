extends RefCounted
class_name DialogueRunner

enum FinishReason {
	COMPLETED,
	CANCELLED,
	INTERRUPTED,
	INVALID_DATA,
}

signal dialogue_started(conversation: DialogueConversation)
signal sequence_started(sequence: DialogueSequence)
signal line_changed(entry: DialogueEntry, page_index: int)
signal responses_changed(responses: Array[DialogueResponse])
signal response_selected(response: DialogueResponse)
signal action_requested(action: DialogueAction, context: Dictionary[StringName, Variant])
signal dialogue_finished(reason: FinishReason)

var condition_evaluator: DialogueConditionEvaluator = DialogueConditionEvaluator.new()

var _conversation: DialogueConversation
var _sequence: DialogueSequence
var _current_entry: DialogueEntry
var _page_index: int = 0
var _entries: Dictionary[StringName, DialogueEntry] = {}
var _visible_responses: Array[DialogueResponse] = []
var _context: Dictionary[StringName, Variant] = {}
var _validation_errors: PackedStringArray = []

func is_running() -> bool:
	return _conversation != null or _sequence != null

func update_context(context: Dictionary[StringName, Variant]) -> void:
	if not is_running():
		return
	_context = context.duplicate()

func start(conversation: DialogueConversation, context: Dictionary[StringName, Variant] = {}) -> bool:
	if is_running():
		return false
	var validation_errors := get_validation_errors(conversation)
	if not validation_errors.is_empty():
		for validation_error: String in validation_errors:
			push_error(validation_error)
		_entries.clear()
		return false
	_conversation = conversation
	_context = context.duplicate()
	dialogue_started.emit(conversation)
	_enter_entry(conversation.start_entry_id)
	return true

func start_sequence(sequence: DialogueSequence, context: Dictionary[StringName, Variant]) -> bool:
	if is_running():
		return false
	if sequence == null:
		return false
	var validation_errors := get_sequence_validation_errors(sequence)
	if not validation_errors.is_empty():
		for validation_error: String in validation_errors:
			push_error(validation_error)
		_entries.clear()
		return false
	var start_entry_id := sequence.get_start_entry_id(context)
	if start_entry_id.is_empty():
		return false
	if not _entries.has(start_entry_id):
		push_error("Dialogue sequence '%s' resolved to missing start entry '%s'." % [sequence.sequence_id, start_entry_id])
		_entries.clear()
		return false
	_sequence = sequence
	_context = context.duplicate()
	sequence_started.emit(sequence)
	_enter_entry(start_entry_id)
	return true

func resolve_sequence(sequences: Array[DialogueSequence], context: Dictionary[StringName, Variant]) -> DialogueSequence:
	var best_sequence: DialogueSequence = null
	for seq: DialogueSequence in sequences:
		if seq == null or not seq.is_eligible(context):
			continue
		if best_sequence == null or _is_higher_priority(seq, best_sequence):
			best_sequence = seq
	return best_sequence

func _is_higher_priority(a: DialogueSequence, b: DialogueSequence) -> bool:
	if a.priority != b.priority:
		return a.priority > b.priority
	return String(a.sequence_id) < String(b.sequence_id)

func advance() -> void:
	if _current_entry == null:
		return
	if not _visible_responses.is_empty():
		return
	if _page_index + 1 < _current_entry.pages.size():
		_page_index += 1
		line_changed.emit(_current_entry, _page_index)
		return
	_visible_responses = _get_available_responses(_current_entry.responses)
	if not _visible_responses.is_empty():
		responses_changed.emit(_visible_responses)
		return
	_complete_entry(_current_entry.next_entry_id)

func choose_response(index: int) -> void:
	if index < 0 or index >= _visible_responses.size():
		return
	var response: DialogueResponse = _visible_responses[index]
	var entry_actions := _current_entry.actions.duplicate()
	var response_actions := response.actions.duplicate()
	_visible_responses.clear()
	_emit_actions(entry_actions)
	_emit_actions(response_actions)
	response_selected.emit(response)
	_enter_entry(response.next_entry_id)

func cancel() -> void:
	if _conversation != null:
		if not _conversation.can_cancel:
			return
		_finish(FinishReason.CANCELLED)
		return
	if _sequence != null:
		if not _sequence.can_cancel:
			return
		_finish(FinishReason.CANCELLED)

func abort() -> void:
	if not is_running():
		return
	_finish(FinishReason.INTERRUPTED)

func _complete_entry(next_entry_id: StringName) -> void:
	_emit_actions(_current_entry.actions)
	_enter_entry(next_entry_id)

func _enter_entry(entry_id: StringName) -> void:
	var remaining_hops: int = _entries.size() + 1
	var candidate_id: StringName = entry_id
	while not candidate_id.is_empty() and remaining_hops > 0:
		remaining_hops -= 1
		var candidate: DialogueEntry = _entries.get(candidate_id)
		if candidate == null:
			_finish(FinishReason.INVALID_DATA)
			return
		if candidate.pages.is_empty():
			push_error("Dialogue entry '%s' has no pages." % candidate.entry_id)
			_finish(FinishReason.INVALID_DATA)
			return
		if condition_evaluator.are_met(candidate.conditions, _context):
			_current_entry = candidate
			_page_index = 0
			_visible_responses.clear()
			line_changed.emit(_current_entry, _page_index)
			return
		candidate_id = candidate.skip_entry_id if not candidate.skip_entry_id.is_empty() else candidate.next_entry_id
	if candidate_id.is_empty():
		_finish(FinishReason.COMPLETED)
	else:
		push_error("Dialogue contains a conditional routing cycle.")
		_finish(FinishReason.INVALID_DATA)

func _get_available_responses(responses: Array[DialogueResponse]) -> Array[DialogueResponse]:
	var result: Array[DialogueResponse] = []
	for response: DialogueResponse in responses:
		if condition_evaluator.are_met(response.conditions, _context):
			result.append(response)
	return result

func _emit_actions(actions: Array[DialogueAction]) -> void:
	for action: DialogueAction in actions:
		action_requested.emit(action, _context)

func _finish(reason: FinishReason) -> void:
	_conversation = null
	_sequence = null
	_current_entry = null
	_page_index = 0
	_entries.clear()
	_visible_responses.clear()
	_context.clear()
	dialogue_finished.emit(reason)

func get_validation_errors(conversation: DialogueConversation) -> PackedStringArray:
	_validation_errors.clear()
	_entries.clear()
	if conversation == null:
		_validation_errors.append("Dialogue conversation is null.")
	else:
		_build_and_validate_entry_index(conversation)
	return _validation_errors.duplicate()

func _build_and_validate_entry_index(conversation: DialogueConversation) -> bool:
	_entries.clear()
	if conversation.conversation_id.is_empty():
		return _record_validation_error("Dialogue conversation has no ID.")
	if conversation.start_entry_id.is_empty():
		return _record_validation_error("Dialogue '%s' has no start entry." % conversation.conversation_id)
	for entry: DialogueEntry in conversation.entries:
		if not _index_entry(entry):
			return false
	if not _entries.has(conversation.start_entry_id):
		return _record_validation_error("Dialogue '%s' start entry '%s' was not found."
		 % [conversation.conversation_id, conversation.start_entry_id])
	for entry: DialogueEntry in conversation.entries:
		if not _validate_entry(entry):
			return false
	return true

func get_sequence_validation_errors(sequence: DialogueSequence) -> PackedStringArray:
	_validation_errors.clear()
	_entries.clear()
	if sequence == null:
		_validation_errors.append("Dialogue sequence is null.")
	else:
		_build_and_validate_sequence_entry_index(sequence)
	return _validation_errors.duplicate()

func _build_and_validate_sequence_entry_index(sequence: DialogueSequence) -> bool:
	_entries.clear()
	if sequence.sequence_id.is_empty():
		return _record_validation_error("Dialogue sequence has no ID.")
	if sequence.entries.is_empty():
		return _record_validation_error("Dialogue sequence '%s' has no entries." % sequence.sequence_id)
	for entry: DialogueEntry in sequence.entries:
		if not _index_entry(entry):
			return false
	if sequence.quest_id < 0:
		if sequence.start_entry_id.is_empty():
			return _record_validation_error("Dialogue sequence '%s' has no start entry." % sequence.sequence_id)
		if not _entries.has(sequence.start_entry_id):
			return _record_validation_error("Dialogue sequence '%s' start entry '%s' was not found." % [sequence.sequence_id, sequence.start_entry_id])
	else:
		if sequence.state_entries.is_empty() and sequence.start_entry_id.is_empty():
			return _record_validation_error("Dialogue sequence '%s' has no state entries or start entry." % sequence.sequence_id)
		for state: StringName in sequence.state_entries:
			var target_entry_id: StringName = sequence.state_entries[state]
			if target_entry_id.is_empty():
				return _record_validation_error("Dialogue sequence '%s' state '%s' has an empty entry ID." % [sequence.sequence_id, state])
			if not _entries.has(target_entry_id):
				return _record_validation_error("Dialogue sequence '%s' state '%s' points to missing entry '%s'." % [sequence.sequence_id, state, target_entry_id])
		if not sequence.start_entry_id.is_empty() and not _entries.has(sequence.start_entry_id):
			return _record_validation_error("Dialogue sequence '%s' start entry '%s' was not found." % [sequence.sequence_id, sequence.start_entry_id])
	for entry: DialogueEntry in sequence.entries:
		if not _validate_entry(entry):
			return false
	return true

func _index_entry(entry: DialogueEntry) -> bool:
	if entry == null:
		return _record_validation_error("Dialogue contains a null entry.")
	if entry.entry_id.is_empty():
		return _record_validation_error("Dialogue contains an entry with no ID.")
	if _entries.has(entry.entry_id):
		return _record_validation_error("Duplicate dialogue entry: %s" % entry.entry_id)
	_entries[entry.entry_id] = entry
	return true

func _validate_entry(entry: DialogueEntry) -> bool:
	if entry.pages.is_empty():
		return _record_validation_error("Dialogue entry '%s' has no pages." % entry.entry_id)
	if not _is_valid_destination(entry.next_entry_id):
		return _report_missing_destination(entry.entry_id, entry.next_entry_id)
	if not _is_valid_destination(entry.skip_entry_id):
		return _report_missing_destination(entry.entry_id, entry.skip_entry_id)
	for condition: DialogueCondition in entry.conditions:
		if not _validate_condition(condition, entry.entry_id):
			return false
	for action: DialogueAction in entry.actions:
		if not _validate_action(action, entry.entry_id):
			return false
	for response: DialogueResponse in entry.responses:
		if not _validate_response(response, entry.entry_id):
			return false
	return true

func _is_valid_destination(entry_id: StringName) -> bool:
	return entry_id.is_empty() or _entries.has(entry_id)

func _report_missing_destination(source_id: StringName, destination_id: StringName) -> bool:
	return _record_validation_error("Dialogue entry '%s' points to missing entry '%s'." % [source_id, destination_id])

func _validate_response(response: DialogueResponse, entry_id: StringName) -> bool:
	if response == null:
		return _record_validation_error("Dialogue entry '%s' contains a null response." % entry_id)
	if response.text.is_empty():
		return _record_validation_error("Dialogue entry '%s' contains an empty response." % entry_id)
	if not _is_valid_destination(response.next_entry_id):
		return _report_missing_destination(entry_id, response.next_entry_id)
	for condition: DialogueCondition in response.conditions:
		if not _validate_condition(condition, entry_id):
			return false
	for action: DialogueAction in response.actions:
		if not _validate_action(action, entry_id):
			return false
	return true

func _validate_condition(condition: DialogueCondition, owner_id: StringName) -> bool:
	if condition == null:
		return _record_validation_error("Dialogue '%s' contains a null condition." % owner_id)
	if condition.condition_id.is_empty():
		return _record_validation_error("Dialogue '%s' contains a condition with no ID." % owner_id)
	return true

func _validate_action(action: DialogueAction, owner_id: StringName) -> bool:
	if action == null:
		return _record_validation_error("Dialogue '%s' contains a null action." % owner_id)
	if action.action_id.is_empty():
		return _record_validation_error("Dialogue '%s' contains an action with no ID." % owner_id)
	return true

func _record_validation_error(message: String) -> bool:
	_validation_errors.append(message)
	return false
