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
	for point in curve.get_baked_points():
		points.append(to_global(point))
	return points


func get_start_index() -> int:
	var waypoint_count := curve.get_baked_points().size()
	if waypoint_count == 0:
		return 0
	return randi_range(0, waypoint_count - 1)
