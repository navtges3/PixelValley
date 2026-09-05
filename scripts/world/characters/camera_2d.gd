extends Camera2D
class_name WorldCamera

@export var tilemap_group: String = "camera_bounds"

func _ready() -> void:
	refresh_limits()

func refresh_limits() -> void:
	var tilemaps := get_tree().get_nodes_in_group(tilemap_group)
	if tilemaps.is_empty():
		push_warning("WorldCamera: no TileMapLayer found in group '%s'" % tilemap_group)
		return

	var combined_rect: Rect2
	var has_valid_tilemap := false

	for node in tilemaps:
		var tilemap := node as TileMapLayer
		if tilemap == null or tilemap.tile_set == null:
			continue
		var used_rect: Rect2i = tilemap.get_used_rect()
		if used_rect.size == Vector2i.ZERO:
			continue
		var tile_size: Vector2i = tilemap.tile_set.tile_size
		var origin: Vector2 = tilemap.global_position

		var world_rect := Rect2(
			origin + Vector2(used_rect.position * tile_size),
			Vector2(used_rect.size * tile_size)
		)
		if not has_valid_tilemap:
			combined_rect = world_rect
			has_valid_tilemap = true
		else:
			combined_rect = combined_rect.merge(world_rect)

	if not has_valid_tilemap:
		push_warning("WorldCamera: no valid TileMapLayer with bounds found in group '%s'" % tilemap_group)
		return

	limit_left   = int(combined_rect.position.x)
	limit_top    = int(combined_rect.position.y)
	limit_right  = int(combined_rect.end.x)
	limit_bottom = int(combined_rect.end.y)
	reset_smoothing()
