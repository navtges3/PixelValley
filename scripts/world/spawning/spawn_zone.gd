
extends Node2D
class_name SpawnZone

const ENEMY_SCENE: PackedScene = preload("res://scenes/world/characters/enemy.tscn")

@export var config: SpawnZoneConfig

@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_positions: Node2D = $SpawnPositions

var _enemies: Array[Enemy] = []
var _initialized := false
var _active := false
var _remaining_time := 0.0
var _player: Node2D

signal enemy_combat_initiated(enemy: Enemy)


func _ready() -> void:
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	if config == null:
		push_error("SpawnZone: Missing configuration Resource.")
		return

	if not config.validate_config():
		push_error("SpawnZone '%s': Invalid configuration." % config.zone_id)


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
# INITIAL AND REPLENISHMENT SPAWNING
# --------------------------------------------------

func _spawn_batch(requested_count: int) -> int:
	if requested_count <= 0:
		return 0

	var available := get_available_capacity()
	var spawn_count := mini(requested_count, available)
	var spawned := 0

	for i in range(spawn_count):
		var marker := _get_available_marker()

		if marker == null:
			break

		var entry := _select_enemy_entry()

		if entry == null:
			break

		if _spawn_enemy(entry, marker):
			spawned += 1

	return spawned


func _spawn_enemy(entry: SpawnEntry, marker: Marker2D) -> bool:
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

	enemy.position = world_parent.to_local(marker.global_position)
	world_parent.add_child.call_deferred(enemy)

	_enemies.append(enemy)
	enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy), CONNECT_ONE_SHOT)

	enemy.set_world_active.call_deferred(_active)

	return true


func _on_enemy_tree_exiting(enemy: Enemy) -> void:
	_enemies.erase(enemy)

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

func _get_available_marker() -> Marker2D:
	var candidates: Array[Marker2D] = []

	for child in spawn_positions.get_children():
		if not child is Marker2D:
			continue

		var marker := child as Marker2D

		if _is_marker_available(marker):
			candidates.append(marker)

	if candidates.is_empty():
		return null

	candidates.shuffle()
	return candidates[0]


func _is_marker_available(marker: Marker2D) -> bool:
	if is_instance_valid(_player):
		if marker.global_position.distance_to(_player.global_position) \
		< config.minimum_player_distance:
			return false
	
	for enemy in _get_living_enemies():
		if enemy.global_position.distance_to(marker.global_position) \
		< config.marker_occupancy_radius:
			return false

	return true


# --------------------------------------------------
# ENEMY SELECTION
# --------------------------------------------------

func _select_enemy_entry() -> SpawnEntry:
	var total_weight := 0

	for entry in config.enemy_pool:
		if entry != null:
			total_weight += maxi(0, entry.weight)

	if total_weight <= 0:
		push_warning("SpawnZone: Enemy pool has no valid weights.")
		return null

	var roll := randi_range(1, total_weight)

	for entry in config.enemy_pool:
		if entry == null:
			continue

		roll -= maxi(0, entry.weight)

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
