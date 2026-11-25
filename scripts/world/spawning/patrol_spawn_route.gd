extends Path2D
class_name PatrolSpawnRoute

@export_range(1, 10) var max_enemies: int = 1
# false = ping-pong (A->B->A), true = closed loop
@export var loop: bool = false


func is_valid() -> bool:
	return curve != null and curve.point_count >= 2


func get_waypoints() -> PackedVector2Array:
	var points := PackedVector2Array()
	if curve == null:
		return points
	for i in curve.point_count:
		points.append(to_global(curve.get_point_position(i)))
	return points


func get_start_index() -> int:
	if not is_valid():
		return 0
	return randi() % maxi(1, curve.point_count)
