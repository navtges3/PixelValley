extends RefCounted
class_name DialogueRunner

enum FinishReason { COMPLETED, CANCELLED, INVALID_DATA }

signal conversation_started(conversation: DialogueConversation)
signal line_changed(entry: DialogueEntry, page_index: int)
signal responses_changed(responses: Array[DialogueResponse])
signal response_selected(response: DialogueResponse)
signal action_requested(action: DialogueAction, context: Dictionary[StringName, Variant])
signal conversation_finished(reason: FinishReason)

var condition_evaluator: DialogueConditionEvaluator = DialogueConditionEvaluator.new()

var _conversation: DialogueConversation
var _current_entry: DialogueEntry
var _page_index: int = 0
var _entries: Dictionary[StringName, DialogueEntry] = {}
var _visible_responses: Array[DialogueResponse] = []
var _context: Dictionary[StringName, Variant] = {}

func is_running() -> bool:
	return _conversation != null

func start(conversation: DialogueConversation, context: Dictionary[StringName, Variant] = {}) -> bool:
	if conversation == null or is_running():
		return false
	_entries.clear()
	for entry: DialogueEntry in conversation.entries:
		if entry == null or entry.entry_id.is_empty():
			continue
		if _entries.has(entry.entry_id):
			push_error("Duplicate dialogue entry: %s" % entry.entry_id)
			return false
		_entries[entry.entry_id] = entry
	if not _entries.has(conversation.start_entry_id):
		push_error("Dialogue start entry was not found.")
		return false
	_conversation = conversation
	_context = context.duplicate()
	conversation_started.emit(conversation)
	_enter_entry(conversation.start_entry_id)
	return true

func advance() -> void:
	if _current_entry == null:
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
	_emit_actions(_current_entry.actions)
	_emit_actions(response.actions)
	response_selected.emit(response)
	_visible_responses.clear()
	_enter_entry(response.next_entry_id)

func cancel() -> void:
	if _conversation == null or not _conversation.can_cancel:
		return
	_finish(FinishReason.CANCELLED)

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
	_current_entry = null
	_page_index = 0
	_visible_responses.clear()
	_context.clear()
	conversation_finished.emit(reason)
