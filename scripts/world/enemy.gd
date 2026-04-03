extends CharacterBody2D
class_name Enemy

signal combat_initiated(enemy: Enemy)

enum State { IDLE, PATROL, CHASE, DEAD }

@export_group("Identity")
@export var monster_id: MonsterLoader.MonsterID = MonsterLoader.MonsterID.GOBLIN

@export_group("Patrol")
@export var patrol_speed: float = 40.0
@export var patrol_range: float = 48.0
@export var idle_wait_time: float = 1.5

@export_group("Detection")
@export var detection_radius: float = 80.0
@export var detection_collision_mask: int = 1

var spawn_point_id: String = ""

var _state: State = State.PATROL
var _origin: Vector2 = Vector2.ZERO
var _patrol_dir: int = 1
var _idle_timer: float = 0.0
var _player_ref: Node2D = null

@onready var detection_area: Area2D = $DetectionArea
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_origin = global_position
	add_to_group("enemies")
	
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	
	var shape := CircleShape2D.new()
	shape.radius = detection_radius
	var col := CollisionShape2D.new()
	col.shape = shape
	detection_area.add_child(col)
	
	detection_area.collision_mask = detection_collision_mask

func _physics_process(delta: float) -> void:
	match _state:
		State.IDLE: _process_idle(delta)
		State.PATROL: _process_patrol(delta)
		State.CHASE: _process_chase()
		State.DEAD: pass

func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	anim.play("idle")
	move_and_slide()
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		_state = State.PATROL

func _process_patrol(_delta: float) -> void:
	var target_x: float = _origin.x + _patrol_dir * patrol_range
	var diff: float = target_x - global_position.x
	
	if abs(diff) < 2.0:
		# reached the waypoint - flip and idle briefly
		_patrol_dir = -_patrol_dir
		_idle_timer = idle_wait_time
		_state = State.IDLE
		velocity = Vector2.ZERO
	else:
		velocity.x = sign(diff) * patrol_speed
		velocity.y = 0.0
	
	move_and_slide()
	_update_sprite_flip()

func _process_chase() -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_ref = body
	_state = State.CHASE
	combat_initiated.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body != _player_ref:
		return
	_player_ref = null
	_state = State.PATROL

func _update_sprite_flip() -> void:
	if velocity.x > 0:
		anim.play("walk_right")
	elif velocity.x < 0:
		anim.play("walk_left")
	else:
		anim.play("idle")

func on_combat_ended(win: bool) -> void:
	if win:
		_state = State.DEAD
		queue_free()
	else:
		_state = State.PATROL
		_player_ref = null
