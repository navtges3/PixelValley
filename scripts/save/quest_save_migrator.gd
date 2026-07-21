extends RefCounted

const CURRENT_SCHEMA_VERSION: int = 2
const LEGACY_SCHEMA_VERSION: int = 0

const QUEST_LIST_KEYS: Array[String] = [
	"locked_quests",
	"offered_quests",
	"active_quests",
	"ready_quests",
	"completed_quests",
]

static func migrate(document: Dictionary, known_quest_ids: Array[int] = [], emit_warnings: bool = true) -> Dictionary:
	var migrated: Dictionary = document.duplicate(true)
	var version: int = int(migrated.get("schema_version", LEGACY_SCHEMA_VERSION))
	if version > CURRENT_SCHEMA_VERSION:
		_report_warning(("QuestSaveMigrator: quest save schema %d is newer than supported schema %d; "
				+ "loading recognized fields only") % [version, CURRENT_SCHEMA_VERSION], emit_warnings)
		return _normalize_document(migrated, known_quest_ids, emit_warnings)
	while version < CURRENT_SCHEMA_VERSION:
		match version:
			LEGACY_SCHEMA_VERSION:
				migrated = _migrate_v0_to_v1(migrated)
			1:
				migrated = _migrate_v1_to_v2(migrated)
			_:
				push_error("QuestSaveMigrator: no migration registered for schema %d" % version)
				return _normalize_document(migrated, known_quest_ids, emit_warnings)
		version += 1
	migrated["schema_version"] = CURRENT_SCHEMA_VERSION
	return _normalize_document(migrated, known_quest_ids, emit_warnings)

static func _migrate_v0_to_v1(document: Dictionary) -> Dictionary:
	var migrated: Dictionary = document.duplicate(true)
	migrated["schema_version"] = 1
	if typeof(migrated.get("data", {})) != TYPE_DICTIONARY:
		migrated["data"] = {}
	return migrated

static func _migrate_v1_to_v2(document: Dictionary) -> Dictionary:
	var migrated: Dictionary = document.duplicate(true)
	var raw_data: Variant = migrated.get("data", {})
	var data: Dictionary = ((raw_data as Dictionary).duplicate(true)
		if typeof(raw_data) == TYPE_DICTIONARY
		else {}
	)
	var legacy_available: Variant = data.get("available_quests", [])
	data.erase("available_quests")
	data["offered_quests"] = []
	data["active_quests"] = []
	data["ready_quests"] = []
	if typeof(legacy_available) == TYPE_ARRAY:
		for raw_quest: Variant in legacy_available as Array:
			if typeof(raw_quest) != TYPE_DICTIONARY:
				continue
			var quest_data := raw_quest as Dictionary
			if bool(quest_data.get("completed", false)):
				data["ready_quests"].append(quest_data)
			else:
				data["active_quests"].append(quest_data)
	else:
		data["active_quests"] = legacy_available
	data["locked_quests"] = data.get("locked_quests", [])
	data["completed_quests"] = data.get("completed_quests", [])
	migrated["data"] = data
	migrated["schema_version"] = 2
	return migrated

static func _normalize_document(document: Dictionary, known_quest_ids: Array[int], emit_warnings: bool) -> Dictionary:
	var normalized: Dictionary = document.duplicate(true)
	var raw_data: Variant = normalized.get("data", {})
	if typeof(raw_data) != TYPE_DICTIONARY:
		_report_warning("QuestSaveMigrator: malformed quest save data; using an empty quest state", emit_warnings)
		raw_data = {}
	var data: Dictionary = (raw_data as Dictionary).duplicate(true)
	var seen_ids: Dictionary[int, bool] = {}
	for list_key: String in QUEST_LIST_KEYS:
		data[list_key] = _normalize_quest_list(data.get(list_key, []), list_key, known_quest_ids, seen_ids, emit_warnings)
	normalized["data"] = data
	return normalized

static func _normalize_quest_list(raw_list: Variant, list_key: String, known_quest_ids: Array[int],
	seen_ids: Dictionary[int, bool], emit_warnings: bool) -> Array[Dictionary]:
	var quests: Array[Dictionary] = []
	if typeof(raw_list) != TYPE_ARRAY:
		_report_warning("QuestSaveMigrator: malformed '%s'; using an empty list" % list_key, emit_warnings)
		return quests
	for record_index: int in (raw_list as Array).size():
		var raw_record: Variant = (raw_list as Array)[record_index]
		if typeof(raw_record) != TYPE_DICTIONARY:
			_report_warning("QuestSaveMigrator: malformed quest record at %s[%d]; skipping"
				% [list_key, record_index], emit_warnings)
			continue
		var quest: Dictionary = _normalize_quest_record(raw_record as Dictionary, emit_warnings)
		var quest_id: int = int(quest["id"])
		if quest_id <= 0:
			_report_warning("QuestSaveMigrator: quest record at %s[%d] has an invalid ID; skipping"
				% [list_key, record_index], emit_warnings)
			continue
		if seen_ids.has(quest_id):
			_report_warning("QuestSaveMigrator: duplicate quest ID %d; skipping later record"
				% quest_id, emit_warnings)
			continue
		seen_ids[quest_id] = true
		if not known_quest_ids.is_empty() and quest_id not in known_quest_ids:
			_report_warning("QuestSaveMigrator: unknown quest ID %d; recovering from its embedded save data"
				% quest_id, emit_warnings)
		quests.append(quest)
	return quests

static func _normalize_quest_record(raw_record: Dictionary, emit_warnings: bool) -> Dictionary:
	var quest: Dictionary = raw_record.duplicate(true)
	quest["id"] = int(quest.get("id", 0))
	quest["title"] = str(quest.get("title", ""))
	quest["description"] = str(quest.get("description", ""))
	var category: int = int(quest.get("category", Quest.Category.MAIN))
	quest["category"] = category if category in Quest.Category.values() else Quest.Category.MAIN
	var source_type: int = int(quest.get("source_type", Quest.SourceType.AUTOMATIC))
	quest["source_type"] = source_type if source_type in Quest.SourceType.values() else Quest.SourceType.AUTOMATIC
	quest["source_id"] = str(quest.get("source_id", ""))
	quest["next_quests"] = _normalize_int_array(quest.get("next_quests", []))
	quest["unlocks_locations"] = _normalize_string_array(quest.get("unlocks_locations", []))
	quest["completed"] = bool(quest.get("completed", false))
	quest["final_quest"] = bool(quest.get("final_quest", false))
	quest["objectives"] = _normalize_objectives(
		quest.get("objectives", []), int(quest["id"]), emit_warnings
	)
	quest["reward"] = _normalize_reward(quest.get("reward", {}), int(quest["id"]), emit_warnings)
	return quest

static func _normalize_objectives(raw_objectives: Variant, quest_id: int, emit_warnings: bool) -> Array[Dictionary]:
	var objectives: Array[Dictionary] = []
	if typeof(raw_objectives) != TYPE_ARRAY:
		_report_warning("QuestSaveMigrator: quest ID %d has malformed objectives; using none" % quest_id, emit_warnings)
		return objectives
	for raw_objective: Variant in raw_objectives as Array:
		if typeof(raw_objective) != TYPE_DICTIONARY:
			_report_warning("QuestSaveMigrator: quest ID %d has a malformed objective; skipping" % quest_id, emit_warnings)
			continue
		var objective: Dictionary = (raw_objective as Dictionary).duplicate(true)
		objective["type"] = str(objective.get("type", "kill"))
		objectives.append(objective)
	return objectives

static func _normalize_reward(raw_reward: Variant, quest_id: int, emit_warnings: bool) -> Dictionary:
	if typeof(raw_reward) != TYPE_DICTIONARY:
		_report_warning("QuestSaveMigrator: quest ID %d has a malformed reward; using defaults"
			% quest_id, emit_warnings)
		raw_reward = {}
	var reward: Dictionary = (raw_reward as Dictionary).duplicate(true)
	reward["experience"] = int(reward.get("experience", 0))
	reward["gold"] = int(reward.get("gold", 0))
	reward["items"] = _normalize_string_array(reward.get("items", []))
	reward["random_weapon"] = bool(reward.get("random_weapon", false))
	var rarity: int = int(reward.get("rarity", Item.Rarity.COMMON))
	reward["rarity"] = rarity if rarity in Item.Rarity.values() else Item.Rarity.COMMON
	return reward

static func _normalize_int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry: Variant in value as Array:
		if typeof(entry) == TYPE_INT or typeof(entry) == TYPE_FLOAT:
			result.append(int(entry))
	return result

static func _normalize_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry: Variant in value as Array:
		if typeof(entry) == TYPE_STRING or typeof(entry) == TYPE_STRING_NAME:
			result.append(str(entry))
	return result

static func _report_warning(message: String, emit_warnings: bool) -> void:
	if emit_warnings:
		push_warning(message)
