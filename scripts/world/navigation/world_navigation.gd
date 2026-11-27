
extends Node2D
class_name WorldNavigation


@export var floor_layer: TileMapLayer
@export var debug_draw_navigation := false:
	set(value):
		debug_draw_navigation = value
		z_index = 100 if value else 0
		queue_redraw()

const CELL_SIZE := Vector2(32, 32)

const WALKABLE_GROUP := "navigation_walkable"
const BLOCKED_GROUP := "navigation_blocked"
const OBSTACLE_GROUP := "navigation_obstacle"

var navigation_grid := AStarGrid2D.new()

@export_group("Dynamic Spatial Grid")
@export var spatial_cell_size: float = 16.0

var _spatial_grid: Dictionary = {}
var _obstacle_cells: Dictionary = {}


func _ready() -> void:
	add_to_group("world_navigation")
	_build_navigation_grid()


func _build_navigation_grid() -> void:
	if floor_layer == null:
		push_error("WorldNavigation: Floor layer reference is missing.")
		return

	navigation_grid.region = floor_layer.get_used_rect()
	navigation_grid.cell_size = CELL_SIZE

	navigation_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation_grid.update()

	for x in range(navigation_grid.region.position.x, navigation_grid.region.end.x):
		for y in range(navigation_grid.region.position.y, navigation_grid.region.end.y):
			navigation_grid.set_point_solid(Vector2i(x, y), true)

	_apply_tilemap_group(WALKABLE_GROUP, false)
	_apply_tilemap_group(BLOCKED_GROUP, true)
	
	z_index = 100 if debug_draw_navigation else 0
	queue_redraw()


func _apply_tilemap_group(group_name: String, is_blocked: bool) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		var layer := node as TileMapLayer

		if layer == null:
			continue

		if not get_parent().is_ancestor_of(layer):
			continue

		for cell in layer.get_used_cells():
			var map_position := layer.to_global(layer.map_to_local(cell))
			var floor_position := floor_layer.to_local(map_position)
			var floor_cell := floor_layer.local_to_map(floor_position)
			
			if navigation_grid.region.has_point(floor_cell):
				navigation_grid.set_point_solid(floor_cell, is_blocked)


func get_navigation_path(start_position: Vector2, target_position: Vector2) -> PackedVector2Array:
	var start_cell := _world_to_grid_cell(start_position)
	var target_cell := _world_to_grid_cell(target_position)

	if not navigation_grid.region.has_point(start_cell) or navigation_grid.is_point_solid(start_cell):
		return PackedVector2Array()

	if not navigation_grid.region.has_point(target_cell) or navigation_grid.is_point_solid(target_cell):
		return PackedVector2Array()

	var cell_path := navigation_grid.get_id_path(start_cell, target_cell)
	var world_path := PackedVector2Array()

	for cell in cell_path:
		world_path.append(floor_layer.to_global(floor_layer.map_to_local(cell)))

	return world_path


func _world_to_grid_cell(world_position: Vector2) -> Vector2i:
	var local_position := floor_layer.to_local(world_position)
	return floor_layer.local_to_map(local_position)


func get_navigation_cell(world_position: Vector2) -> Vector2i:
	return _world_to_grid_cell(world_position)


func _world_to_spatial_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / spatial_cell_size),
		floori(world_position.y / spatial_cell_size)
	)


func register_obstacle(obstacle: CharacterBody2D) -> void:
	if not is_instance_valid(obstacle):
		return
	
	var cell := _world_to_spatial_cell(obstacle.global_position)
	
	if not _spatial_grid.has(cell):
		_spatial_grid[cell] = []
	
	if not _spatial_grid[cell].has(obstacle):
		_spatial_grid[cell].append(obstacle)
	
	_obstacle_cells[obstacle] = cell


func unregister_obstacle(obstacle: CharacterBody2D) -> void:
	if not _obstacle_cells.has(obstacle):
		return

	var cell: Vector2i = _obstacle_cells[obstacle]

	if _spatial_grid.has(cell):
		_spatial_grid[cell].erase(obstacle)

		if _spatial_grid[cell].is_empty():
			_spatial_grid.erase(cell)

	_obstacle_cells.erase(obstacle)


func update_obstacle(obstacle: CharacterBody2D) -> void:
	if not is_instance_valid(obstacle):
		return
	
	var new_cell := _world_to_spatial_cell(obstacle.global_position)
	
	if not _obstacle_cells.has(obstacle):
		register_obstacle(obstacle)
		return
	
	var old_cell: Vector2i = _obstacle_cells[obstacle]
	
	if old_cell == new_cell:
		return
	
	unregister_obstacle(obstacle)
	register_obstacle(obstacle)


func get_nearby_obstacles(world_position: Vector2, detection_radius: float) -> Array[CharacterBody2D]:
	var nearby_obstacles: Array[CharacterBody2D] = []
	
	if detection_radius < 0.0 or spatial_cell_size <= 0.0:
		return nearby_obstacles
	
	var search_offset := Vector2.ONE * detection_radius
	var min_cell := _world_to_spatial_cell(world_position - search_offset)
	var max_cell := _world_to_spatial_cell(world_position + search_offset)
	var detection_radius_squared := detection_radius * detection_radius
	
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			var cell := Vector2i(x, y)
			
			if not _spatial_grid.has(cell):
				continue
			
			for obstacle in _spatial_grid[cell]:
				if not is_instance_valid(obstacle):
					continue
				if obstacle.is_queued_for_deletion():
					continue
				
				var distance_squared := world_position.distance_squared_to(obstacle.global_position)
				
				if distance_squared <= detection_radius_squared:
					nearby_obstacles.append(obstacle)
	
	return nearby_obstacles


func is_position_walkable(world_position: Vector2) -> bool:
	if floor_layer == null:
		return false
	
	var cell := _world_to_grid_cell(world_position)
	
	if not navigation_grid.region.has_point(cell):
		return false
	
	return not navigation_grid.is_point_solid(cell)


func _draw() -> void:
	if not debug_draw_navigation or floor_layer == null:
		return
	
	var walkable_color := Color(0.1, 0.85, 0.25, 0.25)
	var blocked_color := Color(0.95, 0.15, 0.15, 0.35)
	var grid_color := Color(1.0, 1.0, 1.0, 0.25)
	
	for x in range(navigation_grid.region.position.x, navigation_grid.region.end.x):
		for y in range(navigation_grid.region.position.y, navigation_grid.region.end.y):
			var cell := Vector2i(x, y)
			var center := floor_layer.map_to_local(cell)
			var half_size := CELL_SIZE / 2.0
			
			var corners := [
				center + Vector2(-half_size.x, -half_size.y),
				center + Vector2(half_size.x, -half_size.y),
				center + Vector2(half_size.x, half_size.y),
				center + Vector2(-half_size.x, half_size.y)
			]
			
			var polygon := PackedVector2Array()
			
			for corner in corners:
				polygon.append(to_local(floor_layer.to_global(corner)))
			
			var fill_color := blocked_color if navigation_grid.is_point_solid(cell) else walkable_color
			
			draw_colored_polygon(polygon, fill_color)
			
			var outline := polygon.duplicate()
			outline.append(polygon[0])
			draw_polyline(outline, grid_color, 1.0)
