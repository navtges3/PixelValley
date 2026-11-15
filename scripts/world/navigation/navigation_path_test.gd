extends Node2D

@export var world_navigation: WorldNavigation
@export var start_marker: Marker2D
@export var target_marker: Marker2D

var test_path := PackedVector2Array()


func _ready() -> void:
	z_index = 110
	call_deferred("_run_test")


func _run_test() -> void:
	if world_navigation == null:
		push_error("NavigationPathTest: WorldNavigation reference is missing.")
		return
	
	if start_marker == null or target_marker == null:
		push_error("NavigationPathTest: Start or target marker is missing.")
		return
	
	test_path = world_navigation.get_navigation_path(start_marker.global_position, target_marker.global_position)
	
	if test_path.is_empty():
		print("Navigation test: No valid path found.")
	else:
		print("Navigation test: Path found with ", test_path.size(), " cells.")
	
	queue_redraw()


func _draw() -> void:
	if test_path.size() < 2:
		return
	
	var local_path := PackedVector2Array()
	
	for point in test_path:
		local_path.append(to_local(point))
	
	draw_polyline(local_path, Color.YELLOW, 4.0, true)
