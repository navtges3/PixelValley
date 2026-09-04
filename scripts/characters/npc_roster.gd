extends Resource
class_name NpcRoster

@export var npcs: Array[NpcData] = []

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary[StringName, NpcData] = {}
	var seen_sequence_ids: Dictionary[StringName, NpcData] = {}
	for npc: NpcData in npcs:
		if npc == null:
			errors.append("NPC roster contains a null entry.")
			continue
		errors.append_array(npc.get_validation_errors())
		if seen_ids.has(npc.npc_id):
			errors.append("Duplicate NPC ID '%s'." % npc.npc_id)
		else:
			seen_ids[npc.npc_id] = npc
		for sequence: DialogueSequence in npc.dialogue_sequences:
			if sequence == null or sequence.sequence_id.is_empty():
				continue
			if seen_sequence_ids.has(sequence.sequence_id):
				errors.append("Duplicate dialogue sequence ID '%s'." % sequence.sequence_id)
			else:
				seen_sequence_ids[sequence.sequence_id] = npc
	return errors

func get_npc(npc_id: StringName) -> NpcData:
	for npc: NpcData in npcs:
		if npc != null and npc.npc_id == npc_id:
			return npc
	return null

func get_npc_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for npc: NpcData in npcs:
		if npc != null and not npc.npc_id.is_empty():
			result.append(npc.npc_id)
	return result
