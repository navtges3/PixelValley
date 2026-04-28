extends Marker2D
class_name SpawnPoint

const enemy_scene = preload("res://scenes/world/enemy.tscn")

@export var monster_id: MonsterLoader.MonsterID = MonsterLoader.MonsterID.GOBLIN
@export var spawn_count: int = 1
@export var use_existing_children: bool = false
@export var spawn_offset: Vector2 = Vector2(16, 0)
@export var quest_id: int = 0

@export_group("Behavior")
@export var behavior: Enemy.Behavior = Enemy.Behavior.PATROL
@export var wander_bounds_local: Rect2 = Rect2(-64, -16, 128, 32)

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
	var world_bounds := Rect2(
		global_position + wander_bounds_local.position,
		wander_bounds_local.size
	)
	for i in spawn_count:
		var enemy: Enemy = enemy_scene.instantiate() as Enemy
		enemy.monster_id = monster_id
		enemy.spawn_point_id = path
		enemy.behavior = behavior
		enemy.wander_bounds = world_bounds
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
