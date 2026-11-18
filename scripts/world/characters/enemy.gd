extends CharacterBody2D
class_name Enemy

signal combat_initiated(enemy: Enemy)

enum State { IDLE, PATROL, GUARD, WANDER, CHASE, RETURN, DEAD }
enum Behavior { PATROL, GUARD, WANDER }

@export_group("Identity")
@export var encounter: EncounterDefinition = null
@export var monster_id: MonsterLoader.MonsterID = MonsterLoader.MonsterID.GOBLIN_SCOUT

@export_group("Patrol")
@export var patrol_speed: float = 40.0
@export var patrol_range: float = 48.0
@export var idle_wait_time: float = 1.5

@export_group("Detection")
@export var detection_radius: float = 80.0
@export var detection_collision_mask: int = 1

@export_group("Chase")
@export var chase_speed: float = 70.0
@export var chase_duration: float = 3.0
@export var combat_radius: float = 16.0
@export var chase_repath_interval: float = 0.4
@export var chase_repath_distance: float = 16.0

@export_group("Navigation Debug")
@export var debug_navigation_recovery: bool = false

var behavior: Behavior = Behavior.PATROL
var wander_bounds: Rect2 = Rect2(0, 0, 0, 0)
var _wander_target: Vector2 = Vector2.ZERO

var spawn_point_id: String = ""
var spawn_zone_id: StringName = &""
var spawn_instance_id: StringName = &""

var _state: State = State.PATROL
var _origin: Vector2 = Vector2.ZERO
var _patrol_dir: int = 1
var _idle_timer: float = 0.0
var _chase_timer: float = 0.0
var _chase_repath_timer: float = 0.0
var _player_ref: Node2D = null
var _has_reported_recovery_exhaustion: bool = false

var _world_navigation: WorldNavigation

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var character_navigation: CharacterNavigation = $CharacterNavigation
@onready var character_avoidance: CharacterAvoidance = $CharacterAvoidance

func _ready() -> void:
	_origin = global_position
	add_to_group("enemies")
	add_to_group("navigation_obstacle")
	
	_world_navigation = get_tree().get_first_node_in_group("world_navigation") as WorldNavigation
	if _world_navigation != null:
		_world_navigation.register_obstacle(self)
	
	_apply_visuals()
	
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	
	var shape := CircleShape2D.new()
	shape.radius = detection_radius
	var col := CollisionShape2D.new()
	col.shape = shape
	detection_area.add_child(col)
	
	detection_area.collision_mask = detection_collision_mask
	
	_next_behavior()


func _exit_tree() -> void:
	if is_instance_valid(_world_navigation):
		_world_navigation.unregister_obstacle(self)


func _next_behavior() -> void:
	match behavior:
		Behavior.GUARD: _state = State.GUARD
		Behavior.PATROL: _begin_patrol()
		Behavior.WANDER: _begin_wander()

func _apply_visuals() -> void:
	if encounter != null:
		var encounter_visual := encounter.get_lead_world_visual()
		if encounter_visual != null:
			anim.sprite_frames = encounter_visual
			_play_anim("idle")
			return
	var monster: Monster = MonsterLoader.new_monster(monster_id)
	if monster == null or monster.world_visual == null:
		return
	anim.sprite_frames = monster.world_visual
	_play_anim("idle")

func _physics_process(delta: float) -> void:
	match _state:
		State.IDLE:   _process_idle(delta)
		State.PATROL: _process_patrol(delta)
		State.GUARD:  _process_guard()
		State.WANDER: _process_wander(delta)
		State.CHASE:  _process_chase(delta)
		State.RETURN: _process_return()
		State.DEAD: pass
	
	if is_instance_valid(_world_navigation):
		_world_navigation.update_obstacle(self)
	
	if is_inside_tree() and is_physics_processing():
		var is_stuck := character_navigation.update_stuck_detection(delta)

		if is_stuck:
			if character_navigation.attempt_path_recovery():
				if debug_navigation_recovery:
					print("Navigation recovery attempted: ", name)
			elif (character_navigation.has_exhausted_recovery_attempts()
					and not _has_reported_recovery_exhaustion):
				if debug_navigation_recovery:
					print("Navigation recovery exhausted: ", name)
				_has_reported_recovery_exhaustion = true
		else:
			_has_reported_recovery_exhaustion = false

func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	_play_anim("idle")
	move_and_slide()
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		_next_behavior()

func _process_guard() -> void:
	velocity = Vector2.ZERO
	_play_anim("idle")
	move_and_slide()

func _begin_patrol() -> void:
	var target_x: float = _origin.x + _patrol_dir * patrol_range
	var target_position := Vector2(target_x, _origin.y)
	
	if character_navigation.set_destination(target_position):
		_state = State.PATROL
	else:
		push_warning("Enemy could not find a patrol path.")
		_state = State.GUARD

func _process_patrol(_delta: float) -> void:
	if character_navigation.is_navigation_finished():
		_patrol_dir = -_patrol_dir
		_idle_timer = idle_wait_time
		_state = State.IDLE
		velocity = Vector2.ZERO
	else:
		velocity = _get_movement_velocity(patrol_speed)
	
	move_and_slide()
	_update_walk_anim()

func _begin_wander() -> void:
	if wander_bounds.size == Vector2.ZERO:
		_state = State.GUARD
		return
	
	# Try several random positions in case one is blocked.
	for attempt in range(5):
		var random_offset = Vector2(
			randf_range(
				wander_bounds.position.x,
				wander_bounds.position.x + wander_bounds.size.x
			),
			randf_range(
				wander_bounds.position.y,
				wander_bounds.position.y + wander_bounds.size.y
			)
		)
		
		_wander_target = _origin + random_offset
		
		if character_navigation.set_destination(_wander_target):
			_state = State.WANDER
			return
	
	push_warning("Enemy could not find a valid wander destination.")
	_state = State.GUARD

func _process_wander(_delta: float) -> void:
	if character_navigation.is_navigation_finished():
		velocity = Vector2.ZERO
		_idle_timer = idle_wait_time
		_state = State.IDLE
	else:
		velocity = _get_movement_velocity(patrol_speed)
	
	move_and_slide()
	_update_walk_anim()

func _process_chase(delta: float) -> void:
	if _player_ref == null:
		_begin_return()
		return
	
	var to_player: Vector2 = _player_ref.global_position - global_position
	
	# Combat takes priority over movement.
	if to_player.length() <= combat_radius:
		character_navigation.stop()
		velocity = Vector2.ZERO
		move_and_slide()
		_update_walk_anim()
		combat_initiated.emit(self)
		return
	
	# Preserve the existing chase duration.
	_chase_timer -= delta
	if _chase_timer <= 0.0:
		_begin_return()
		return
	
	# Periodically recalculate the path toward the player's current position.
	_chase_repath_timer -= delta
	
	if _chase_repath_timer <= 0.0:
		character_navigation.set_destination_if_changed(_player_ref.global_position, chase_repath_distance)
		_chase_repath_timer = chase_repath_interval
	
	# Follow the current path, or remain stationary if no path exists.
	velocity = _get_movement_velocity(chase_speed)
	
	move_and_slide()
	_update_walk_anim()

func _begin_return() -> void:
	_player_ref = null
	character_navigation.stop()
	
	if character_navigation.set_destination(_origin):
		_state = State.RETURN
	else:
		push_warning("Enemy could not find a return path to its origin.")
		_state = State.GUARD

func _process_return() -> void:
	if character_navigation.is_navigation_finished():
		velocity = Vector2.ZERO
		_next_behavior()
		return
	
	velocity = _get_movement_velocity(patrol_speed)
	
	move_and_slide()
	_update_walk_anim()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _state == State.CHASE or _state == State.DEAD:
		return
	_player_ref = body
	_chase_timer = chase_duration
	_chase_repath_timer = 0.0
	character_navigation.stop()
	_state = State.CHASE

func _on_body_exited(body: Node2D) -> void:
	if body != _player_ref:
		return
	_player_ref = null

func _update_walk_anim() -> void:
	if velocity.x > 0:
		_play_anim("walk_right")
	elif velocity.x < 0:
		_play_anim("walk_left")
	elif velocity.y > 0:
		_play_anim("walk_down")
	elif velocity.y < 0:
		_play_anim("walk_up")
	else:
		_play_anim("idle")

func _play_anim(anim_name: String) -> void:
	if anim.animation != anim_name:
		anim.play(anim_name)

func on_combat_ended(win: bool) -> void:
	if win:
		_state = State.DEAD
		queue_free()
	else:
		_player_ref = null
		_next_behavior()

func set_world_active(active: bool) -> void:
	set_physics_process(active)
	if is_node_ready():
		detection_area.set_deferred("monitoring", active)
		detection_area.set_deferred("monitorable", active)
	if not active and _state == State.CHASE:
		_begin_return()

func _get_movement_velocity(move_speed: float) -> Vector2:
	var desired_velocity := character_navigation.get_desired_velocity(move_speed)
	var avoidance_velocity := character_avoidance.get_avoidance_velocity(desired_velocity)
	
	return (desired_velocity + avoidance_velocity).limit_length(move_speed)
