
extends Node2D
class_name SpawnZone

const ENEMY_SCENE: PackedScene = preload("res://scenes/world/characters/enemy.tscn")
const POSITION_ATTEMPTS := 5

@export var config: SpawnZoneConfig

@onready var spawn_timer: Timer = $SpawnTimer

var _wander_areas: Array[WanderSpawnArea] = []
var _patrol_routes: Array[PatrolSpawnRoute] = []
var _guard_posts: Array[GuardSpawnPost] = []

var _enemy_sources: Dictionary = {}

var _enemies: Array[Enemy] = []
var _initialized := false
var _active := false
var _remaining_time := 0.0
var _player: Node2D

signal enemy_combat_initiated(enemy: Enemy)


func _ready() -> void:
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	_collect_sources(self)

	if config == null:
		push_error("SpawnZone: Missing configuration Resource.")
		return

	if not config.validate_config():
		push_error("SpawnZone '%s': Invalid configuration." % config.zone_id)
	
	_validate_sources()


# --------------------------------------------------
# PUBLIC API
# --------------------------------------------------

func initialize() -> void:
	if _initialized:
		return

	if config == null or not config.validate_config():
		return

	_initialized = true

	_spawn_batch(config.initial_spawn_count)

	if get_available_capacity() > 0:
		_schedule_replenishment()


func set_player(player: Node2D) -> void:
	_player = player


func activate() -> void:
	if _active:
		return

	_active = true

	for enemy in _get_living_enemies():
		enemy.set_world_active(true)

	if not _initialized:
		initialize()
		return

	if get_available_capacity() > 0:
		_schedule_replenishment()


func deactivate() -> void:
	if not _active:
		return

	_active = false

	if spawn_timer.time_left > 0.0:
		_remaining_time = spawn_timer.time_left
	else:
		_remaining_time = config.spawn_interval

	spawn_timer.stop()

	for enemy in _get_living_enemies():
		enemy.set_world_active(false)


func get_alive_count() -> int:
	return _get_living_enemies().size()


func get_available_capacity() -> int:
	if config == null:
		return 0

	return maxi(0, config.max_alive - get_alive_count())


func get_is_initialized() -> bool:
	return _initialized


func is_active() -> bool:
	return _active


# --------------------------------------------------
# SPAWN SOURCE
# --------------------------------------------------

func _collect_sources(node: Node) -> void:
	for child in node.get_children():
		if child is WanderSpawnArea:
			_wander_areas.append(child as WanderSpawnArea)
		elif child is PatrolSpawnRoute:
			var route := child as PatrolSpawnRoute
			if route.is_valid():
				_patrol_routes.append(route)
			else:
				push_warning("SpawnZone: route '%s' needs at least 2 points." % route.name)
		elif child is GuardSpawnPost:
			_guard_posts.append(child as GuardSpawnPost)
		_collect_sources(child)


func _validate_sources() -> void:
	var total_capacity := 0
	for behavior in [Enemy.Behavior.WANDER, Enemy.Behavior.PATROL, Enemy.Behavior.GUARD]:
		for source in _get_sources(behavior):
			total_capacity += _get_source_capacity(source)
	
	for entry in config.enemy_pool:
		if entry != null and _get_sources(entry.behavior).is_empty():
			push_warning("SpawnZone '%s': pool has a %s entry but the zone has no matching source." \
					% [config.zone_id, Enemy.Behavior.keys()[entry.behavior]])
	
	if config.max_alive > total_capacity:
		push_warning("SpawnZone '%s': max_alive (%d) exceeds total source capacity (%d)." \
				% [config.zone_id, config.max_alive, total_capacity])


func _get_sources(behavior: Enemy.Behavior) -> Array:
	match behavior:
		Enemy.Behavior.WANDER: return _wander_areas
		Enemy.Behavior.PATROL: return _patrol_routes
		Enemy.Behavior.GUARD: return _guard_posts
	return []


func _get_source_capacity(source: Node) -> int:
	if source is WanderSpawnArea:
		return (source as WanderSpawnArea).max_enemies
	if source is PatrolSpawnRoute:
		return (source as PatrolSpawnRoute).max_enemies
	return GuardSpawnPost.MAX_ENEMIES


func _get_source_occupancy(source: Node) -> int:
	var count := 0
	for enemy in _get_living_enemies():
		if _enemy_sources.get(enemy) == source:
			count += 1
	return count


func _has_free_source(behavior: Enemy.Behavior) -> bool:
	for source in _get_sources(behavior):
		if _get_source_occupancy(source) < _get_source_capacity(source):
			return true
	return false


# --------------------------------------------------
# INITIAL AND REPLENISHMENT SPAWNING
# --------------------------------------------------

func _spawn_batch(requested_count: int) -> int:
	if requested_count <= 0:
		return 0

	var available := get_available_capacity()
	var spawn_count := mini(requested_count, available)
	var spawned := 0

	for i in range(spawn_count):
		var entry := _select_enemy_entry()
		if entry == null:
			break

		var location := _pick_spawn_location(entry.behavior)
		if location.is_empty():
			break

		if _spawn_enemy(entry, location["source"], location["position"]):
			spawned += 1

	return spawned


func _spawn_enemy(entry: SpawnEntry, source: Node, spawn_pos: Vector2) -> bool:
	var enemy := ENEMY_SCENE.instantiate() as Enemy

	if enemy == null:
		push_error("SpawnZone: Failed to instantiate Enemy.")
		return false

	# Set exported/runtime configuration before adding the node.
	# Enemy._ready() uses its initial position as its origin.
	enemy.monster_id = entry.monster_id
	enemy.behavior = entry.behavior
	enemy.patrol_speed = entry.patrol_speed
	enemy.patrol_range = entry.patrol_range
	enemy.idle_wait_time = entry.idle_wait_time
	enemy.wander_bounds = entry.wander_bounds
	
	if entry.behavior == Enemy.Behavior.WANDER and source is WanderSpawnArea:
		enemy.wander_area = source as WanderSpawnArea
	
	elif entry.behavior == Enemy.Behavior.PATROL and source is PatrolSpawnRoute:
		var route := source as PatrolSpawnRoute
		enemy.patrol_route = route
		enemy.patrol_waypoints = route.get_waypoints()
		
		var closest_index := 0
		var closest_distance := INF
		for i in range(enemy.patrol_waypoints.size()):
			var distance := spawn_pos.distance_squared_to(enemy.patrol_waypoints[i])
			if distance < closest_distance:
				closest_distance = distance
				closest_index = i
		
		enemy.patrol_waypoint_index = closest_index
		
		if not route.loop:
			enemy.patrol_direction = -1 if randf() < 0.5 else 1
	
	enemy.combat_initiated.connect(_on_enemy_combat_initiated)

	# Dynamic identity is separate from fixed SpawnPoint identity.
	enemy.spawn_zone_id = config.zone_id
	enemy.spawn_instance_id = StringName("%s_%s" % [config.zone_id, str(get_instance_id()) + "_" + str(Time.get_ticks_usec())])

	# Spawn beside this node in the world/Y-sort parent.
	var world_parent := get_parent() as Node2D

	if world_parent == null:
		enemy.queue_free()
		push_error("SpawnZone: No Node2D world parent available.")
		return false

	enemy.position = world_parent.to_local(spawn_pos)
	world_parent.add_child.call_deferred(enemy)

	_enemies.append(enemy)
	_enemy_sources[enemy] = source
	
	enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy), CONNECT_ONE_SHOT)
	enemy.set_world_active.call_deferred(_active)

	return true


func _on_enemy_tree_exiting(enemy: Enemy) -> void:
	_enemies.erase(enemy)
	_enemy_sources.erase(enemy)

	if _active and get_available_capacity() > 0:
		_schedule_replenishment()


func _on_spawn_timer_timeout() -> void:
	if not _active:
		return

	_prune_enemies()

	var capacity := get_available_capacity()
	if capacity <= 0:
		return

	var batch_size := randi_range(config.min_spawn_count, config.max_spawn_count)
	batch_size = mini(batch_size, capacity)
	_spawn_batch(batch_size)
	if get_available_capacity() > 0:
		_schedule_replenishment()


func _schedule_replenishment() -> void:
	if not _active:
		return

	if get_available_capacity() <= 0:
		return

	if spawn_timer.is_stopped():
		var delay := config.spawn_interval

		if _remaining_time > 0.0:
			delay = _remaining_time

		_remaining_time = 0.0
		spawn_timer.start(delay)


# --------------------------------------------------
# SPAWN POSITION SELECTION
# --------------------------------------------------

# Returns {} when nothing is available, else {"source": Node, "position": Vector2}
func _pick_spawn_location(behavior: Enemy.Behavior) -> Dictionary:
	var sources := _get_sources(behavior).duplicate()
	sources.shuffle()
	for source in sources:
		if _get_source_occupancy(source) >= _get_source_capacity(source):
			continue
		var patrol_waypoints := PackedVector2Array()
		if source is PatrolSpawnRoute:
			patrol_waypoints = (source as PatrolSpawnRoute).get_waypoints()
			if patrol_waypoints.size() < 2:
				continue
		for attempt in POSITION_ATTEMPTS:
			var spawn_pos: Vector2
			if source is PatrolSpawnRoute:
				spawn_pos = patrol_waypoints[randi_range(0, patrol_waypoints.size() - 1)]
			else:
				spawn_pos = _get_spawn_position(source)
			if _is_position_valid(spawn_pos):
				return {"source": source, "position": spawn_pos}
	return {}


func _get_spawn_position(source: Node) -> Vector2:
	if source is WanderSpawnArea:
		return (source as WanderSpawnArea).get_random_point()
	return (source as GuardSpawnPost).get_spawn_position()


func _is_position_valid(pos: Vector2) -> bool:
	if is_instance_valid(_player):
		if pos.distance_to(_player.global_position) < config.minimum_player_distance:
			return false
	for enemy in _get_living_enemies():
		if enemy.global_position.distance_to(pos) < config.marker_occupancy_radius:
			return false
	return true


# --------------------------------------------------
# ENEMY SELECTION
# --------------------------------------------------

func _select_enemy_entry() -> SpawnEntry:
	var candidates: Array[SpawnEntry] = []
	var total_weight := 0

	for entry in config.enemy_pool:
		if entry == null or entry.weight <= 0:
			continue
		if not _has_free_source(entry.behavior):
			continue
		candidates.append(entry)
		total_weight += entry.weight

	if total_weight <= 0:
		return null

	var roll := randi_range(1, total_weight)
	for entry in candidates:
		roll -= entry.weight
		if roll <= 0:
			return entry
	return null


# --------------------------------------------------
# POPULATION MAINTENANCE
# --------------------------------------------------

func _get_living_enemies() -> Array[Enemy]:
	var living: Array[Enemy] = []

	for enemy in _enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			living.append(enemy)

	_enemies = living
	return living


func _prune_enemies() -> void:
	_get_living_enemies()

# --------------------------------------------------
# COMBAT PASSTHROUGH
# --------------------------------------------------
func _on_enemy_combat_initiated(enemy: Enemy) -> void:
	enemy_combat_initiated.emit(enemy)
