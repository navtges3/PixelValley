extends Node
class_name CharacterNavigation


@export var world_navigation: WorldNavigation
@export var arrival_distance: float = 4.0

@export_group("Stuck Detection")
@export var stuck_check_interval: float = 1.0
@export var minimum_progress_distance: float = 2.0

var _character: CharacterBody2D
var _path := PackedVector2Array()
var _path_index: int = 0
var _has_destination: bool = false
var _progress_timer: float = 0.0
var _last_progress_position: Vector2 = Vector2.ZERO
var _is_stuck: bool = false


func _ready() -> void:
	_character = get_parent() as CharacterBody2D
	
	if _character == null:
		push_error("CharacterNavigation must be a child of CharacterBody2D")
		return
	
	_last_progress_position = _character.global_position
	
	if world_navigation == null:
		world_navigation = get_tree().get_first_node_in_group("world_navigation") as WorldNavigation
	
	if world_navigation == null:
		push_error("CharacterNavigation could not find WorldNavigation.")


func set_destination(target_position: Vector2) -> bool:
	if world_navigation == null or _character == null:
		return false
	
	_path = world_navigation.get_navigation_path(_character.global_position, target_position)
	
	_path_index = 0
	_has_destination = not _path.is_empty()
	
	_reset_stuck_detection()
	return _has_destination


func stop() -> void:
	_path.clear()
	_path_index = 0
	_has_destination = false
	_reset_stuck_detection()


func is_navigation_finished() -> bool:
	return not _has_destination


func get_desired_velocity(move_speed: float) -> Vector2:
	if not _has_destination or _character == null:
		return Vector2.ZERO
	
	# Skip waypoints that have already been reached.
	while _path_index < _path.size():
		var waypoint := _path[_path_index]
		
		if _character.global_position.distance_to(waypoint) > arrival_distance:
			break
		
		_path_index += 1
	
	# All waypoints have been reached.
	if _path_index >= _path.size():
		stop()
		return Vector2.ZERO
	
	var target := _path[_path_index]
	var direction := _character.global_position.direction_to(target)
	
	return direction * move_speed


func update_stuck_detection(delta: float) -> bool:
	if not _has_destination or _character == null:
		_reset_stuck_detection()
		return false
	
	_progress_timer += delta
	
	if _progress_timer < stuck_check_interval:
		return _is_stuck
	
	var distance_moved := _character.global_position.distance_to(_last_progress_position)
	_is_stuck = distance_moved < minimum_progress_distance
	_last_progress_position = _character.global_position
	_progress_timer = 0.0
	return _is_stuck


func _reset_stuck_detection() -> void:
	_progress_timer = 0.0
	_is_stuck = false

	if _character != null:
		_last_progress_position = _character.global_position
