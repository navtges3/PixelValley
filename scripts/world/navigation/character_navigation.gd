extends Node
class_name CharacterNavigation


@export var world_navigation: WorldNavigation
@export var arrival_distance: float = 4.0

var _character: CharacterBody2D
var _path := PackedVector2Array()
var _path_index: int = 0
var _has_destination: bool = false


func _ready() -> void:
	_character = get_parent() as CharacterBody2D
	
	if _character == null:
		push_error("CharacterNavigation must be a child of CharacterBody2D")
		return
	
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
	
	return _has_destination


func stop() -> void:
	_path.clear()
	_path_index = 0
	_has_destination = false


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
