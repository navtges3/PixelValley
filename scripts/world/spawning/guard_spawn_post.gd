extends Marker2D
class_name GuardSpawnPost

# Always holds one guard. For two guards, place two posts.
const MAX_ENEMIES := 1


func get_spawn_position() -> Vector2:
	return global_position
