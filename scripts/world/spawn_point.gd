extends Marker2D
class_name SpawnPoint

const enemy_scene = preload("res://scenes/world/enemy.tscn")

@export var monster_id: MonsterLoader.MonsterID = MonsterLoader.MonsterID.GOBLIN
@export var spawn_count: int = 1
@export var use_existing_children: bool = false
@export var spawn_offset: Vector2 = Vector2(16, 0)
@export var quest_id: int = 0

var spawned_enemies: Array[Enemy] = []

func spawn(parent: Node, combat_handler: Callable, location_id: String) -> void:
	var path = str(get_path())
	if quest_id > 0:
		if not _is_quest_active(quest_id):
			return
	if WorldManager.is_spawner_defeated(location_id, path):
		return
	if use_existing_children:
		_wire_existing_children(combat_handler)
		return
	for i in spawn_count:
		var enemy: Enemy = enemy_scene.instantiate() as Enemy
		enemy.monster_id = monster_id
		enemy.spawn_point_id = path
		enemy.global_position = global_position + spawn_offset * i
		parent.add_child(enemy)
		spawned_enemies.append(enemy)
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

func _is_quest_active(id: int) -> bool:
	if GameState.quest_manager == null:
		return false
	for quest in GameState.quest_manager.available_quests:
		if quest.id == id:
			return true
	return false
