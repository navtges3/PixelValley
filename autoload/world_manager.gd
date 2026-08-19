extends Node

# Structure of locations:
# {
#  "forest": {
#   "unlocked": true || false
#   "defeated_spawners": ["../.../SpawnPoint", ...]
#   "claimed_loot_ids": []
#  },
#  "orc_war_camp": { ... },
#  ...
# }
var _locations: Dictionary = {}

# --- Unlock API ---
func unlock_location(location_id: String) -> void:
	var loc := _get_or_create(location_id)
	loc["unlocked"] = true

func is_unlocked(location_id: String) -> bool:
	if not _locations.has(location_id):
		return false
	return _locations[location_id]["unlocked"]

# --- Spawner API ---
func mark_spawner_defeated(location_id: String, spawner_path: String) -> void:
	var loc := _get_or_create(location_id)
	if spawner_path not in loc["defeated_spawners"]:
		loc["defeated_spawners"].append(spawner_path)

func is_spawner_defeated(location_id: String, spawner_path: String) -> bool:
	if not _locations.has(location_id):
		return false
	return spawner_path in _locations[location_id]["defeated_spawners"]

func reset_location_spawners(location_id: String) -> void:
	if _locations.has(location_id):
		_locations[location_id]["defeated_spawners"] = []

# --- World Loot API ---
func mark_loot_claimed(location_id: String, loot_id: String) -> bool:
	if location_id.is_empty():
		push_error("WorldManager: location ID cannot be empty.")
		return false
	if loot_id.is_empty():
		push_error("WorldManager: loot ID cannot be empty.")
		return false
	var location := _get_or_create(location_id)
	var claimed_ids: Array = location["claimed_loot_ids"]
	if loot_id in claimed_ids:
		return false
	claimed_ids.append(loot_id)
	return true

func is_loot_claimed(location_id: String, loot_id: String) -> bool:
	if location_id.is_empty() or loot_id.is_empty():
		return false
	if not _locations.has(location_id):
		return false
	return loot_id in _locations[location_id].get("claimed_loot_ids", [])

# --- Serialization (called by SaveManager) ---
func get_save_data() -> Dictionary:
	return _locations.duplicate(true)

func load_save_data(data: Dictionary) -> void:
	_locations.clear()
	for location_id: String in data:
		var raw: Dictionary = data[location_id]
		var location := _get_or_create(location_id)
		location["unlocked"] = bool(raw.get("unlocked", false))
		for path: String in raw.get("defeated_spawners", []):
			if path not in location["defeated_spawners"]:
				location["defeated_spawners"].append(path)
		for loot_id: String in raw.get("claimed_loot_ids", []):
			if not loot_id.is_empty() and loot_id not in location["claimed_loot_ids"]:
				location["claimed_loot_ids"].append(loot_id)

func reset() -> void:
	_locations.clear()
	unlock_location("forest")

# --- Internal ---
func _get_or_create(location_id: String) -> Dictionary:
	if not _locations.has(location_id):
		_locations[location_id] = {
			"unlocked": false,
			"defeated_spawners": [],
			"claimed_loot_ids": [],
		}
	return _locations[location_id]
