extends Node

# Structure of locations:
# {
#  "forest": {
#   "unlocked": true || false
#   "defeated_spawners": ["../.../SpawnPoint", ...]
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

# --- Serialization (called by SaveManager) ---
func get_save_data() -> Dictionary:
	return _locations.duplicate(true)

func load_save_data(data: Dictionary) -> void:
	_locations.clear()
	for location_id in data:
		var raw: Dictionary = data[location_id]
		var loc := _get_or_create(location_id)
		for path in raw.get("defeated_spawners", []):
			loc["defeated_spawners"].append(path)

func reset() -> void:
	_locations.clear()
	unlock_location("forest")

# --- Internal ---
func _get_or_create(location_id: String) -> Dictionary:
	if not _locations.has(location_id):
		_locations[location_id] = {
			"unlocked": false,
			"defeated_spawners": []
		}
	return _locations[location_id]
