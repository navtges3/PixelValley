extends RefCounted
class_name DialogueState

signal fact_changed(npc_id: StringName, fact_id: StringName)

var _facts_by_npc: Dictionary[StringName, Dictionary] = {}

func has_fact(npc_id: StringName, fact_id: StringName) -> bool:
	var npc_facts: Dictionary = _facts_by_npc.get(npc_id, {})
	return bool(npc_facts.get(fact_id, false))

func claim_fact(npc_id: StringName, fact_id: StringName) -> bool:
	if npc_id.is_empty() or fact_id.is_empty():
		push_warning("DialogueState: NPC and fact IDs must not be empty")
		return false
	if has_fact(npc_id, fact_id):
		return false
	var npc_facts: Dictionary = _facts_by_npc.get(npc_id, {})
	npc_facts[fact_id] = true
	_facts_by_npc[npc_id] = npc_facts
	fact_changed.emit(npc_id, fact_id)
	return true

func get_facts(npc_id: StringName) -> Dictionary:
	return _facts_by_npc.get(npc_id, {}).duplicate()

func clear() -> void:
	_facts_by_npc.clear()

func load_save_data(data: Dictionary) -> void:
	clear()
	var raw_facts: Variant = data.get("npc_facts", {})
	if typeof(raw_facts) != TYPE_DICTIONARY:
		return
	for raw_npc_id: Variant in raw_facts:
		var npc_id := StringName(str(raw_npc_id))
		var raw_fact_ids: Variant = (raw_facts as Dictionary)[raw_npc_id]
		if npc_id.is_empty() or typeof(raw_fact_ids) != TYPE_ARRAY:
			continue
		var npc_facts: Dictionary = {}
		for raw_fact_id: Variant in raw_fact_ids as Array:
			if typeof(raw_fact_id) != TYPE_STRING and typeof(raw_fact_id) != TYPE_STRING_NAME:
				continue
			var fact_id := StringName(str(raw_fact_id))
			if not fact_id.is_empty():
				npc_facts[fact_id] = true
		if not npc_facts.is_empty():
			_facts_by_npc[npc_id] = npc_facts

func get_save_data() -> Dictionary:
	var serialized: Dictionary = {}
	for npc_id: StringName in _facts_by_npc:
		var fact_ids: Array[String] = []
		var npc_facts: Dictionary = _facts_by_npc[npc_id]
		for fact_id: StringName in npc_facts:
			if bool(npc_facts[fact_id]):
				fact_ids.append(String(fact_id))
		fact_ids.sort()
		serialized[String(npc_id)] = fact_ids
	return {"npc_facts": serialized}
