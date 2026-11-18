extends Node
class_name CharacterAvoidance


@export var detection_radius: float = 32.0
@export var preferred_distance: float = 20.0
@export var avoidance_strength: float = 1.0

var _character: CharacterBody2D
var _world_navigation: WorldNavigation


func _ready() -> void:
	_character = get_parent() as CharacterBody2D
	
	if _character == null:
		push_error("CharacterAvoidance must be a child of CharacterBody2D.")
		return
	
	_world_navigation = get_tree().get_first_node_in_group("world_navigation") as WorldNavigation
	
	if _world_navigation == null:
		push_error("CharacterAvoidance could not find WorldNavigation.")


func get_nearby_obstacles() -> Array[CharacterBody2D]:
	var nearby_obstacles: Array[CharacterBody2D] = []
	
	if _character == null or _world_navigation == null:
		return nearby_obstacles
	
	var candidates := _world_navigation.get_nearby_obstacle(_character.global_position, detection_radius)
	
	for obstacle in candidates:
		if obstacle == _character:
			continue
		nearby_obstacles.append(obstacle)
	
	return nearby_obstacles


func get_avoidance_velocity(desired_velocity: Vector2) -> Vector2:
	if (_character == null or _world_navigation == null or
		desired_velocity.is_zero_approx()):
		return Vector2.ZERO

	var desired_direction := desired_velocity.normalized()
	var avoidance_direction := Vector2.ZERO
	var should_yield := false

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

		var sidestep_direction := Vector2(desired_direction.y, -desired_direction.x)
		var sidestep_position := _character.global_position + sidestep_direction * preferred_distance

		if _world_navigation.is_position_walkable(sidestep_position):
			avoidance_direction += sidestep_direction * urgency
			continue

		sidestep_direction *= -1.0
		sidestep_position = _character.global_position + sidestep_direction * preferred_distance

		if _world_navigation.is_position_walkable(sidestep_position):
			avoidance_direction += sidestep_direction * urgency
			continue

		if _character.get_instance_id() < obstacle.get_instance_id():
			should_yield = true

	if not avoidance_direction.is_zero_approx():
		return (
			avoidance_direction.normalized()
			* desired_velocity.length()
			* avoidance_strength
		)
	
	if should_yield:
		return -desired_velocity
	
	return Vector2.ZERO
