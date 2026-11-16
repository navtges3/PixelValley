
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


func _ready() -> void:
	add_to_group("world_navigation")
	_build_navigation_grid()


func _build_navigation_grid() -> void:
	if floor_layer == null:
		push_error("WorldNavigation: Floor layer reference is missing.")
		return

	# Establish grid boundaries using the forest floor.
	navigation_grid.region = floor_layer.get_used_rect()
	navigation_grid.cell_size = CELL_SIZE

	# Prevent diagonal movement through blocked corners.
	navigation_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation_grid.update()

	# Start with every cell blocked.
	# Walkable layers will explicitly enable their occupied cells.
	for x in range(navigation_grid.region.position.x, navigation_grid.region.end.x):
		for y in range(navigation_grid.region.position.y, navigation_grid.region.end.y):
			navigation_grid.set_point_solid(Vector2i(x, y), true)

	# Apply walkable terrain first.
	_apply_tilemap_group(WALKABLE_GROUP, false)

	# Apply permanent obstacles last.
	# Blocked terrain always takes priority.
	_apply_tilemap_group(BLOCKED_GROUP, true)
	
	z_index = 100 if debug_draw_navigation else 0
	queue_redraw()


func _apply_tilemap_group(group_name: String, is_blocked: bool) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		var layer := node as TileMapLayer

		# This initial implementation rasterizes TileMapLayers.
		if layer == null:
			continue

		# Only process nodes belonging to this world scene.
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
			
			# Calculate the four corners of this tile.
			var corners := [
				center + Vector2(-half_size.x, -half_size.y),
				center + Vector2(half_size.x, -half_size.y),
				center + Vector2(half_size.x, half_size.y),
				center + Vector2(-half_size.x, half_size.y)
			]
			
			# Convert floor-layer coordinates into WorldNavigation coordinates.
			var polygon := PackedVector2Array()
			
			for corner in corners:
				polygon.append(to_local(floor_layer.to_global(corner)))
			
			var fill_color := blocked_color if navigation_grid.is_point_solid(cell) else walkable_color
			
			draw_colored_polygon(polygon, fill_color)
			
			# Draw a subtle outline around each cell
			var outline := polygon.duplicate()
			outline.append(polygon[0])
			draw_polyline(outline, grid_color, 1.0)
