extends Marker2D
class_name SpawnPoint

@export var enemy_scene: PackedScene
@export var spawn_count: int = 1
@export var use_existing_children: bool = false
@export var spawn_offset: Vector2 = Vector2(16, 0)

var spawned_enemies: Array[Enemy] = []

func spawn(parent: Node, combat_handler: Callable, location_id: String) -> void:
	var path = str(get_path())
	if WorldManager.is_spawner_defeated(location_id, path):
		return

	if use_existing_children:
		_wire_existing_children(combat_handler)
		return
	
	if enemy_scene == null:
		push_error("SpawnPoint '%s': enemy_scene is not set." % name)
		return
	
	for i in spawn_count:
		var enemy: Enemy = enemy_scene.instantiate() as Enemy
		if enemy == null:
			push_error("SpawnPoint '%s': enemy_scene does not contain an Enemy node." % name)
			continue
		enemy.global_position = global_position + spawn_offset * i
		parent.add_child(enemy)
		spawned_enemies.append(enemy)
		enemy.spawn_point_id = path
		enemy.combat_initiated.connect(combat_handler)

func _wire_existing_children(combat_handler: Callable) -> void:
	var path = str(get_path())
	for child in get_children():
		var enemy := child as Enemy
		if enemy == null:
			continue
		spawned_enemies.append(enemy)
		enemy.spawn_point_id = path
		if not enemy.combat_initiated.is_connected(combat_handler):
			enemy.combat_initiated.connect(combat_handler)
