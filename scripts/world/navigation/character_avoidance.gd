extends Node
class_name CharacterAvoidance


@export var detection_radius: float = 32.0

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
