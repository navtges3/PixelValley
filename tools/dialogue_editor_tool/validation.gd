## Static helper that inspects a DialogueConversation and returns a list of
## human-readable warnings: dangling entry_id references, duplicate ids,
## missing speakers/pages, empty response text, and so on.
class_name DialogueValidator
extends RefCounted

static func validate(conversation: DialogueConversation) -> Array[String]:
	var issues: Array[String] = []
	if conversation == null:
		return issues

	var all_ids: Dictionary = {}
	for entry in conversation.entries:
		if entry != null:
			all_ids[String(entry.entry_id)] = true

	if String(conversation.start_entry_id) != "" and not all_ids.has(String(conversation.start_entry_id)):
		issues.append("Start entry '%s' does not exist." % conversation.start_entry_id)

	var seen_ids: Dictionary = {}
	for entry in conversation.entries:
		if entry == null:
			issues.append("Conversation contains a null entry.")
			continue

		var id_str := String(entry.entry_id)
		if id_str == "":
			issues.append("An entry has no entry_id set.")
		elif seen_ids.has(id_str):
			issues.append("Duplicate entry_id '%s'." % id_str)
		else:
			seen_ids[id_str] = true

		if String(entry.next_entry_id) != "" and not all_ids.has(String(entry.next_entry_id)):
			issues.append("Entry '%s' -> next_entry_id '%s' does not exist." % [id_str, entry.next_entry_id])

		if String(entry.skip_entry_id) != "" and not all_ids.has(String(entry.skip_entry_id)):
			issues.append("Entry '%s' -> skip_entry_id '%s' does not exist." % [id_str, entry.skip_entry_id])

		if entry.speaker == null:
			issues.append("Entry '%s' has no speaker assigned." % id_str)

		if entry.pages.is_empty():
			issues.append("Entry '%s' has no dialogue pages." % id_str)

		for response in entry.responses:
			if response == null:
				continue
			if String(response.next_entry_id) != "" and not all_ids.has(String(response.next_entry_id)):
				issues.append("Entry '%s' response '%s' -> next_entry_id '%s' does not exist." % [id_str, _short(response.text), response.next_entry_id])
			if response.text.strip_edges() == "":
				issues.append("Entry '%s' has a response with empty text." % id_str)

	return issues

static func _short(text: String) -> String:
	if text.length() <= 24:
		return text
	return text.substr(0, 24) + "..."
