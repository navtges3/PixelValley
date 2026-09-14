extends RefCounted
class_name PartySaveMigrator

const CURRENT_SCHEMA_VERSION := 2

static func migrate(document: Dictionary, emit_warnings: bool = true) -> Dictionary:
	var migrated := document.duplicate(true)
	var version := int(migrated.get("schema_version", 1))
	if version > CURRENT_SCHEMA_VERSION:
		if emit_warnings:
			push_warning(
				"PartySaveMigrator: save schema %d is newer than supported schema %d"
				% [version, CURRENT_SCHEMA_VERSION]
			)
		return _normalize(migrated)

	var raw_data: Variant = migrated.get("data", {})
	var data: Dictionary = (
		(raw_data as Dictionary).duplicate(true)
		if typeof(raw_data) == TYPE_DICTIONARY
		else {}
	)
	if version < CURRENT_SCHEMA_VERSION:
		data.erase("active_member_ids")
	migrated["schema_version"] = CURRENT_SCHEMA_VERSION
	migrated["data"] = data
	return _normalize(migrated)

static func _normalize(document: Dictionary) -> Dictionary:
	var normalized := document.duplicate(true)
	var raw_data: Variant = normalized.get("data", {})
	var data: Dictionary = (
		(raw_data as Dictionary).duplicate(true)
		if typeof(raw_data) == TYPE_DICTIONARY
		else {}
	)
	var raw_members: Variant = data.get("members", [])
	if typeof(raw_members) != TYPE_ARRAY:
		data["members"] = []
		raw_members = []

	var member_ids: Array[String] = []
	for raw_member: Variant in raw_members as Array:
		if typeof(raw_member) != TYPE_DICTIONARY:
			continue
		var member := raw_member as Dictionary
		var hero_id := str(member.get("hero_id", ""))
		if hero_id.is_empty() or hero_id in member_ids:
			hero_id = "hero_%d" % member_ids.size()
			while hero_id in member_ids:
				hero_id = "hero_%d" % (member_ids.size() + 1)
			member["hero_id"] = hero_id
		member_ids.append(hero_id)

	var raw_active: Variant = data.get("active_member_ids", [])
	var active_ids: Array[String] = []
	if typeof(raw_active) == TYPE_ARRAY:
		for raw_id: Variant in raw_active as Array:
			var hero_id := str(raw_id)
			if hero_id.is_empty() or hero_id in active_ids or hero_id not in member_ids:
				continue
			active_ids.append(hero_id)
			if active_ids.size() >= Party.MAX_ACTIVE_MEMBERS:
				break
	if raw_active is Array and (raw_active as Array).is_empty():
		active_ids = member_ids.slice(0, Party.MAX_ACTIVE_MEMBERS)
	elif typeof(raw_active) != TYPE_ARRAY:
		active_ids = member_ids.slice(0, Party.MAX_ACTIVE_MEMBERS)

	data["active_member_ids"] = active_ids
	normalized["schema_version"] = CURRENT_SCHEMA_VERSION
	normalized["data"] = data
	return normalized
