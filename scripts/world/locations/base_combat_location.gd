extends BaseLocation
class_name BaseCombatLocation

# Override with the location's LOCATION_ID string constant
func _get_location_id() -> String:
	return ""

func _on_location_ready() -> void:
	_activate_spawn_points()
	_restore_combat_position()

func _restore_combat_position() -> void:
	if GameState.pre_combat_position != Vector2.ZERO:
		player.global_position = GameState.pre_combat_position
		GameState.pre_combat_position = Vector2.ZERO

func _activate_spawn_points() -> void:
	var points: Array = []
	for node in get_tree().get_nodes_in_group("spawn_point"):
		if node is SpawnPoint and not points.has(node):
			points.append(node)
	for sp in points:
		sp.spawn(self, _on_combat_initiated, _get_location_id())

func _on_combat_initiated(enemy: Enemy) -> void:
	enemy.set_physics_process(false)
	GameState.pre_combat_position = player.global_position
	ScreenManager.go_to_screen(ScreenManager.ScreenName.BATTLE, "", {
		"hero": GameState.hero,
		"monster_id": enemy.monster_id,
		"spawn_point_id": enemy.spawn_point_id,
		"location_id": _get_location_id()
	})
