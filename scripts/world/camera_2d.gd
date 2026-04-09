extends Camera2D
class_name WorldCamera

@export var tilemap_group: String = "camera_bounds"

func _ready() -> void:
	_apply_tilemap_limits()

func _apply_tilemap_limits() -> void:
	var tilemaps := get_tree().get_nodes_in_group(tilemap_group)
	if tilemaps.is_empty():
		push_warning("WorldCamera: no TileMapLayer found in group '%s'" % tilemap_group)
		return
	
	var tilemap := tilemaps[0] as TileMapLayer
	if tilemap == null:
		push_warning("WorldCamera: node in group '%s' is not a TileMapLayer" % tilemap_group)
		return
	
	var used_rect: Rect2i = tilemap.get_used_rect()
	var tile_size: Vector2i = tilemap.tile_set.tile_size
	var origin: Vector2 = tilemap.global_position

	var world_rect := Rect2(
		origin + Vector2(used_rect.position * tile_size),
		Vector2(used_rect.size * tile_size)
	)

	limit_left   = int(world_rect.position.x)
	limit_top    = int(world_rect.position.y)
	limit_right  = int(world_rect.end.x)
	limit_bottom = int(world_rect.end.y)
