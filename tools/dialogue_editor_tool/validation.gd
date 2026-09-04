## Static helper for the editor's live validation panel.
##
## DialogueRunner owns the runtime sequence validation rules, so the editor
## delegates those checks and adds editor-specific warnings for missing
## speakers and state-entry targets.
class_name DialogueValidator
extends RefCounted

static func validate(sequence: DialogueSequence) -> Array[String]:
	var issues: Array[String] = []
	var runner := DialogueRunner.new()
	var runner_errors := runner.get_sequence_validation_errors(sequence)
	for error: String in runner_errors:
		issues.append(error)

	if sequence == null:
		return issues

	var entry_ids: Dictionary = {}
	for entry: DialogueEntry in sequence.entries:
		if entry != null:
			entry_ids[String(entry.entry_id)] = true

	for state in sequence.state_entries.keys():
		var state_name := String(state)
		var target_id := String(sequence.state_entries[state])
		if state_name == "":
			issues.append("Dialogue sequence contains a state entry with no state.")
		elif target_id == "":
			issues.append("Dialogue sequence state '%s' has an empty entry ID." % state_name)
		elif not entry_ids.has(target_id):
			var missing_state_message := "Dialogue sequence state '%s' points to missing entry '%s'." % [state_name, target_id]
			if not issues.has(missing_state_message):
				issues.append(missing_state_message)

	for entry: DialogueEntry in sequence.entries:
		if entry == null:
			continue
		if entry.speaker == null:
			issues.append("Dialogue entry '%s' has no speaker assigned." % entry.entry_id)
		for response: DialogueResponse in entry.responses:
			if response != null and not response.text.is_empty() and response.text.strip_edges() == "":
				issues.append(
					"Dialogue entry '%s' has a response with empty text." % entry.entry_id
				)

	return issues
