extends Path2D
class_name PatrolSpawnRoute

@export_range(1, 10) var max_enemies: int = 1
# false = ping-pong (A->B->A), true = closed loop
@export var loop: bool = false


func is_valid() -> bool:
	return curve != null and curve.point_count >= 2


func get_waypoints() -> PackedVector2Array:
	var points := PackedVector2Array()
	if not is_valid():
		return points
	var world_navigation := get_tree().get_first_node_in_group("world_navigation") as WorldNavigation
	if world_navigation == null:
		push_warning("PatrolSpawnRoute: Could not find WorldNavigation.")
		return points
	var previous_cell := Vector2i.ZERO
	var has_previous_cell := false
	for local_point in curve.get_baked_points():
		var world_point := to_global(local_point)
		var cell := world_navigation.get_navigation_cell(world_point)
		if not world_navigation.is_position_walkable(world_point):
			continue
		if has_previous_cell and cell == previous_cell:
			continue
		points.append(world_point)
		previous_cell = cell
		has_previous_cell = true
	return points


func get_start_index() -> int:
	var waypoint_count := get_waypoints().size()
	if waypoint_count == 0:
		return 0
	return randi_range(0, waypoint_count - 1)
