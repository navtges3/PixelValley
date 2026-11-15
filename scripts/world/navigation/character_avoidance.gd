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



func get_avoidance_velocity(desired_velocity: Vector2) -> Vector2:
	if _character == null or desired_velocity.is_zero_approx():
		return Vector2.ZERO

	var desired_direction := desired_velocity.normalized()
	var avoidance_direction := Vector2.ZERO

	for obstacle in get_nearby_obstacles():
		var offset := _character.global_position - obstacle.global_position
		var distance_squared := offset.length_squared()
		var distance: float

		if distance_squared <= 0.001:
			offset = Vector2.RIGHT

			if _character.get_instance_id() > obstacle.get_instance_id():
				offset = Vector2.LEFT

			distance = 0.0
		else:
			distance = sqrt(distance_squared)

		if distance >= preferred_distance:
			continue

		var urgency := 1.0 - (distance / preferred_distance)

		# Calculate a consistent sidestep direction for both enemies.
		var sidestep_direction := desired_direction.rotated(PI / 2.0)

		if _character.get_instance_id() > obstacle.get_instance_id():
			sidestep_direction *= -1.0

		var separation_direction := offset.normalized()

		# Favor sidestepping while maintaining separation.
		var steering_direction := separation_direction * 0.25 + sidestep_direction * 0.75

		avoidance_direction += steering_direction * urgency

	if avoidance_direction.is_zero_approx():
		return Vector2.ZERO

	return (
		avoidance_direction.normalized()
		* desired_velocity.length()
		* avoidance_strength
	)
