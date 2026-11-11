
extends Resource
class_name SpawnZoneConfig

@export_group("Identity")
@export var zone_id: StringName
@export var region_id: StringName

@export_group("Population")
@export_range(1, 20) var max_alive: int = 5
@export_range(0, 20) var initial_spawn_count: int = 3

@export_group("Replenishment")
@export_range(1, 10) var min_spawn_count: int = 1
@export_range(1, 10) var max_spawn_count: int = 2
@export_range(1.0, 600.0) var spawn_interval: float = 60.0

@export_group("Placement")
@export_range(0.0, 1000.0) var minimum_player_distance: float = 96.0
@export_range(1.0, 64.0) var marker_occupancy_radius: float = 12.0

@export_group("Enemies")
@export var enemy_pool: Array[SpawnEntry] = []


func validate_config() -> bool:
	var valid := true

	if zone_id == &"":
		push_warning("SpawnZoneConfig: zone_id cannot be empty.")
		valid = false

	if region_id == &"":
		push_warning("SpawnZoneConfig: region_id cannot be empty.")
		valid = false

	if max_alive < 1:
		push_warning("SpawnZoneConfig: max_alive must be at least 1.")
		valid = false

	if initial_spawn_count > max_alive:
		push_warning("SpawnZoneConfig: initial population exceeds max_alive.")
		valid = false

	if min_spawn_count > max_spawn_count:
		push_warning("SpawnZoneConfig: minimum batch exceeds maximum batch.")
		valid = false

	if spawn_interval <= 0.0:
		push_warning("SpawnZoneConfig: spawn_interval must be positive.")
		valid = false

	if enemy_pool.is_empty():
		push_warning("SpawnZoneConfig: enemy_pool cannot be empty.")
		valid = false

	return valid
