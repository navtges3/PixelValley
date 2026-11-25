extends Area2D
class_name WanderSpawnArea

@export_range(1, 10) var max_enemies: int = 1

@onready var _shape_node: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	monitoring = false
	monitorable = false
	if _shape_node == null or not (_shape_node.shape is RectangleShape2D or _shape_node.shape is CircleShape2D):
		push_warning("WanderSpawnArea '%s': needs a Rectangle or Circle shape." % name)


func get_random_point() -> Vector2:
	var shape := _shape_node.shape
	var local := Vector2.ZERO
	
	if shape is RectangleShape2D:
		var half := (shape as RectangleShape2D).size * 0.5
		local = Vector2(
			randf_range(-half.x, half.x),
			randf_range(-half.y, half.y))
	elif shape is CircleShape2D:
		var radius := (shape as CircleShape2D).radius
		local = Vector2.from_angle(randf() * TAU) * radius * sqrt(randf())
	
	return _shape_node.to_global(local)
