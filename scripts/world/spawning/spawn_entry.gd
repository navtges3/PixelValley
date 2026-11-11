extends Resource
class_name SpawnEntry

@export_group("Enemy")
@export var monster_id: MonsterLoader.MonsterID = MonsterLoader.MonsterID.GOBLIN_SCOUT

@export_group("Behavior")
@export var behavior: Enemy.Behavior = Enemy.Behavior.PATROL

@export_range(1.0, 200.0) var patrol_speed: float = 40.0
@export_range(1.0, 200.0) var patrol_range: float = 48.0
@export_range(0.0, 20.0) var idle_wait_time: float = 1.5

@export_group("Wander")
@export var wander_bounds: Rect2 = Rect2(0, 0, 96, 96)

@export_group("Selection")
@export_range(1, 100) var weight: int = 1
