extends RefCounted

const CURRENT_SCHEMA_VERSION: int = 1
const LEGACY_SCHEMA_VERSION: int = 0

static func migrate(document: Dictionary, known_npc_ids: Array[StringName] = [], emit_warnings: bool = true) -> Dictionary:
	var migrated := document.duplicate(true)
	var version := int(migrated.get("schema_version", LEGACY_SCHEMA_VERSION))
	if version > CURRENT_SCHEMA_VERSION:
		_report_warning(
			("DialogueSaveMigrator: dialogue save schema %d is newer than "
			+ "supported schema %d; loading recognized fields only")
			% [version, CURRENT_SCHEMA_VERSION], emit_warnings)
		return _normalize_document(migrated, known_npc_ids, emit_warnings)
	while version < CURRENT_SCHEMA_VERSION:
		match version:
			LEGACY_SCHEMA_VERSION:
				migrated = _migrate_v0_to_v1(migrated)
			_:
				push_error("DialogueSaveMigrator: no migration registered for schema %d" % version)
				return _normalize_document(migrated, known_npc_ids, emit_warnings)
		version += 1
	migrated["schema_version"] = CURRENT_SCHEMA_VERSION
	return _normalize_document(migrated, known_npc_ids, emit_warnings)

static func _migrate_v0_to_v1(document: Dictionary) -> Dictionary:
	var migrated := document.duplicate(true)
	if typeof(migrated.get("data", {})) != TYPE_DICTIONARY:
		migrated["data"] = {}
	migrated["schema_version"] = 1
	return migrated

static func _normalize_document(document: Dictionary, known_npc_ids: Array[StringName], emit_warnings: bool) -> Dictionary:
	var normalized := document.duplicate(true)
	var raw_data: Variant = normalized.get("data", {})
	if typeof(raw_data) != TYPE_DICTIONARY:
		_report_warning("DialogueSaveMigrator: malformed dialogue save data; using empty state", emit_warnings)
		raw_data = {}
	var raw_npc_facts: Variant = (raw_data as Dictionary).get("npc_facts", {})
	if typeof(raw_npc_facts) != TYPE_DICTIONARY:
		_report_warning("DialogueSaveMigrator: malformed 'npc_facts'; using empty state", emit_warnings)
		raw_npc_facts = {}

	var npc_facts: Dictionary = {}
	for raw_npc_id: Variant in raw_npc_facts:
		var npc_id := StringName(str(raw_npc_id))
		if npc_id.is_empty():
			_report_warning("DialogueSaveMigrator: empty NPC ID; skipping record", emit_warnings)
			continue
		if not known_npc_ids.is_empty() and npc_id not in known_npc_ids:
			_report_warning("DialogueSaveMigrator: unknown NPC ID '%s'; skipping record" % npc_id, emit_warnings)
			continue
		var raw_fact_ids: Variant = (raw_npc_facts as Dictionary)[raw_npc_id]
		if typeof(raw_fact_ids) != TYPE_ARRAY:
			_report_warning("DialogueSaveMigrator: malformed facts for NPC '%s'; skipping record" % npc_id, emit_warnings)
			continue
		var fact_ids: Array[String] = []
		for raw_fact_id: Variant in raw_fact_ids as Array:
			if typeof(raw_fact_id) != TYPE_STRING and typeof(raw_fact_id) != TYPE_STRING_NAME:
				continue
			var fact_id := str(raw_fact_id)
			if fact_id.is_empty() or fact_id in fact_ids:
				continue
			fact_ids.append(fact_id)
		fact_ids.sort()
		if not fact_ids.is_empty():
			npc_facts[String(npc_id)] = fact_ids

	normalized["data"] = {"npc_facts": npc_facts}
	return normalized

static func _report_warning(message: String, emit_warnings: bool) -> void:
	if emit_warnings:
		push_warning(message)
