extends Node2D

@onready var player: CharacterBody2D = $Player

var _pending_entrance_id: String = ""

func _ready() -> void:
	for zone in get_tree().get_nodes_in_group("trigger_zone"):
		zone = zone as TriggerZone
		if zone == null:
			continue
		zone.zone_entered.connect(_on_zone_entered)
	if _pending_entrance_id != "":
		place_player_at_entrance(_pending_entrance_id)
	_activate_spawn_points()

func _activate_spawn_points() -> void:
	var points: Array = []
	for node in get_tree().get_nodes_in_group("spawn_point"):
		if node is SpawnPoint and not points.has(node):
			points.append(node)
	for sp in points:
		sp.spawn(self, _on_combat_initiated)

func _on_combat_initiated(enemy: Enemy) -> void:
	enemy.set_physics_process(false)
	push_warning("Forest: combat_initiated with enemy type '%s'. Wire up CombatManager here." % enemy.enemy_type)

func place_player_at_entrance(entrance_id: String) -> void:
	if not is_node_ready():
		_pending_entrance_id = entrance_id
		return
	for zone in get_tree().get_nodes_in_group("trigger_zone"):
		zone = zone as TriggerZone
		if zone == null:
			continue
		if entrance_id == zone.entrance_id:
			$Player.place_at_entrance(zone)
			return
	push_warning("Entrance not found: ", entrance_id)

func _on_zone_entered(zone: TriggerZone) -> void:
	player.on_zone_entered(zone)
