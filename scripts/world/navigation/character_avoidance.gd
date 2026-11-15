extends Node
class_name CharacterAvoidance


@export var detection_radius: float = 32.0
@export var preferred_distance: float = 20.0
@export var avoidance_strength: float = 1.0

var _character: CharacterBody2D


func _ready() -> void:
	_character = get_parent() as CharacterBody2D
	
	if _character == null:
		push_error("CharacterAvoidance must be a child of CharacterBody2D.")


func get_nearby_obstacles() -> Array[CharacterBody2D]:
	var nearby: Array[CharacterBody2D] = []
	
	if _character == null:
		return nearby
	
	var detection_radius_squared := detection_radius * detection_radius
	
	for node in get_tree().get_nodes_in_group("navigation_obstacle"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		
		var obstacle := node as CharacterBody2D
		
		if obstacle == null or obstacle == _character:
			continue
		
		var distance_squared := _character.global_position.distance_squared_to(obstacle.global_position)
		
		if distance_squared <= detection_radius_squared:
			nearby.append(obstacle)
		
	return nearby


func get_avoidance_velocity(move_speed: float) -> Vector2:
	if _character == null:
		return Vector2.ZERO
	
	var avoidance_direction := Vector2.ZERO
	
	for obstacle in get_nearby_obstacles():
		var offset := _character.global_position - obstacle.global_position
		var distance_squared := offset.length_squared()
		
		if distance_squared <= 0.001:
			continue
		
		var distance := sqrt(distance_squared)
		
		if distance >= preferred_distance:
			continue
		
		# The closer the obstacle, the stronger the avoidance.
		var urgency := 1.0 - (distance / preferred_distance)
		
		avoidance_direction += offset.normalized() * urgency
	
	if avoidance_direction.is_zero_approx():
		return Vector2.ZERO
	
	return avoidance_direction.normalized() * move_speed * avoidance_strength
