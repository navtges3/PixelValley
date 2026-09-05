extends TestCase

const Game = preload("res://scripts/game/game.gd")
const GAME_SCENE := preload("res://scenes/game/game.tscn")

func _ready() -> void:
	if get_tree().current_scene == self:
		await run_async_tests()
		get_tree().quit(_failures)

func run_tests() -> int:
	push_error("Use run_async_tests() for coroutine-based test execution.")
	return 1

func run_async_tests() -> int:
	_begin_test_run()
	await get_tree().process_frame

	var game := GAME_SCENE.instantiate() as Game
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	await _wait_for_transition()

	_expect_not_null(Game.get_instance(), "Game instance should be registered")
	_expect_not_null(Game.get_player(), "Game should have persistent player")
	_expect_not_null(Game.get_world(), "Game should have persistent world")

	var player := Game.get_player()
	var initial_player_id := player.get_instance_id()
	_expect_true(Game.get_instance() == game, "Game.get_instance() should return the scene tree Game")
	_expect_true(_get_player_nodes().size() == 1, "The scene tree should contain exactly one Player")
	_expect_true(player.is_in_group("player"), "Persistent Player should be in the 'player' group")

	ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE)
	await _wait_for_transition()

	var village := Game.get_current_location() as VillageLocation
	_expect_not_null(village, "Village should be loaded as current location")
	_expect_true(Game.get_current_location() == village, "Game should track the requested Village location")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance should not change in Village")
	_expect_true(player.get_parent() == village.y_sorted_world, "Player should be reparented to Village YSortedWorld")
	_expect_true(player.visible, "Player should be visible in Village")
	_expect_true(player.is_in_group("player"), "Player should remain in the 'player' group")
	_expect_equal(player.global_position, VillageLocation.DEFAULT_SPAWN_POSITION, "Player should be at Village default spawn")
	_expect_equal(GameState.player_location["scene"], ScreenManager.ScreenName.VILLAGE, "GameState should track Village")
	_expect_true(_get_player_nodes().size() == 1, "Village should not create a duplicate Player")

	var village_camera := player.get_camera()
	_expect_not_null(village_camera, "Persistent Player should provide a WorldCamera")
	var village_limits := _camera_limits(village_camera)

	var previous_location: BaseLocation = village
	ScreenManager.go_to_screen(ScreenManager.ScreenName.VALLEY, "village")
	await _wait_for_transition()

	var valley := Game.get_current_location() as ValleyLocation
	_expect_not_null(valley, "Valley should be loaded as current location")
	_expect_true(Game.get_current_location() == valley, "Game should track the requested Valley location")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance should not change in Valley")
	_expect_true(player.get_parent() == valley.y_sorted_world, "Player should be reparented to Valley YSortedWorld")
	_expect_true(not is_instance_valid(previous_location), "Previous world location should be freed after transition")
	_expect_equal(GameState.player_location["scene"], ScreenManager.ScreenName.VALLEY, "GameState should track Valley")
	_expect_equal(GameState.player_location["entrance_id"], "village", "GameState entrance should be village")
	_expect_true(_get_player_nodes().size() == 1, "Valley should not create a duplicate Player")
	_expect_true(_camera_limits(player.get_camera()) != village_limits, "WorldCamera limits should refresh for the new location")

	previous_location = valley
	ScreenManager.go_to_screen(ScreenManager.ScreenName.FOREST, "forest")
	await _wait_for_transition()

	var forest := Game.get_current_location() as ForestLocation
	_expect_not_null(forest, "Forest should be loaded as current location")
	_expect_true(Game.get_current_location() == forest, "Game should track the requested Forest location")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance should not change in Forest")
	_expect_true(player.get_parent() == forest.y_sorted_world, "Player should be reparented to Forest YSortedWorld")
	_expect_true(not is_instance_valid(previous_location), "Valley should be freed after entering Forest")
	_expect_equal(GameState.player_location["scene"], ScreenManager.ScreenName.FOREST, "GameState should track Forest")
	_expect_equal(GameState.player_location["entrance_id"], "forest", "GameState entrance should be forest")
	_expect_true(_get_player_nodes().size() == 1, "Forest should not create a duplicate Player")

	var battle_pos := Vector2(200, 300)
	player.global_position = battle_pos
	GameState.pre_combat_position = battle_pos
	var battle_data := {
		"hero": HeroLoader.new_hero(Hero.HeroClass.KNIGHT),
		"monster_id": MonsterLoader.MonsterID.GOBLIN,
	}
	ScreenManager.go_to_screen(ScreenManager.ScreenName.BATTLE, "", {
		"hero": battle_data["hero"],
		"monster_id": battle_data["monster_id"],
	})
	await _wait_for_transition()

	_expect_null(Game.get_current_location(), "Current location should be null during Battle")
	_expect_not_null(Game.get_current_ui(), "BattleScreen should be active UI")
	_expect_true(Game.get_current_ui() is BattleScreen, "Current UI should be BattleScreen")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance ID should not change in Battle")
	_expect_true(player.get_parent() == game, "Player should be reparented to Game root during Battle")
	_expect_true(not player.visible, "Player should be hidden during Battle")
	_expect_true(not player.is_physics_processing(), "Player movement should be disabled during Battle")
	_expect_equal((Game.get_current_ui() as BattleScreen).battle_config, battle_data, "Battle setup data should be preserved")
	_expect_true(not ScreenManager.get_world_hud().visible, "WorldHUD should be hidden during Battle")
	_expect_true(_get_player_nodes().size() == 1, "Battle should not create a duplicate Player")

	ScreenManager.go_back()
	await _wait_for_transition()

	forest = Game.get_current_location() as ForestLocation
	_expect_not_null(forest, "Forest should be restored after returning from Battle")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance ID should not change on Battle return")
	_expect_true(player.get_parent() == forest.y_sorted_world, "Player should be reparented to Forest YSortedWorld")
	_expect_true(player.visible, "Player should be visible again after Battle")
	_expect_equal(player.global_position, battle_pos, "Player position should be restored from pre_combat_position")
	_expect_equal(GameState.pre_combat_position, Vector2.ZERO, "pre_combat_position should be reset after restore")
	_expect_true(ScreenManager.get_world_hud().visible, "WorldHUD should be visible after returning to the world")

	previous_location = forest
	ScreenManager.go_to_screen(ScreenManager.ScreenName.INN, "inn")
	await _wait_for_transition()

	var inn := Game.get_current_location() as InnInterior
	_expect_not_null(inn, "Inn interior should be loaded as current location")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance ID should not change in Inn")
	_expect_true(player.get_parent() == inn.y_sorted_world, "Player should be reparented to Inn YSortedWorld")
	_expect_true(not is_instance_valid(previous_location), "Forest should be freed after entering the Inn")
	_expect_equal(GameState.player_location["scene"], ScreenManager.ScreenName.INN, "GameState should track the Inn")
	_expect_equal(GameState.player_location["entrance_id"], "inn", "GameState entrance should be inn")

	ScreenManager.go_to_screen(ScreenManager.ScreenName.MAIN_MENU)
	await _wait_for_transition()

	_expect_null(Game.get_current_location(), "Current location should be null at Main Menu")
	_expect_not_null(Game.get_current_ui(), "Main Menu should be active UI")
	_expect_true(Game.get_current_ui() is MainMenuScreen, "Current UI should be MainMenuScreen")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance ID should not change at Main Menu")
	_expect_true(player.get_parent() == game, "Player should be reparented to Game root at Main Menu")
	_expect_true(not player.visible, "Player should be hidden at Main Menu")
	_expect_true(not ScreenManager.get_world_hud().visible, "WorldHUD should be hidden at Main Menu")
	_expect_true(_get_player_nodes().size() == 1, "Main Menu should not create a duplicate Player")

	ScreenManager.go_to_screen(ScreenManager.ScreenName.NEW_GAME)
	await _wait_for_transition()
	var new_game_screen := Game.get_current_ui() as NewGameScreen
	_expect_not_null(new_game_screen, "New Game screen should be active")
	GameState.hero = HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	new_game_screen.new_game_window._start_new_game_in_slot(1)
	await _wait_for_transition()
	_expect_true(Game.get_current_location() is VillageLocation, "New Game should transition to Village")
	_expect_equal(player.get_instance_id(), initial_player_id, "New Game should preserve the Player instance")
	_expect_true(player.visible, "Player should be visible after starting a new game")
	_expect_true(_get_player_nodes().size() == 1, "New Game should not create a duplicate Player")

	game.queue_free()
	await get_tree().process_frame

	return _finish_test_run("Persistent Player Architecture")

func _wait_for_transition() -> void:
	await get_tree().process_frame
	while ScreenManager.is_transitioning():
		await get_tree().process_frame
	await get_tree().process_frame

func _get_player_nodes() -> Array[Node]:
	var players: Array[Node] = []
	players.assign(get_tree().get_nodes_in_group("player"))
	return players

func _camera_limits(camera: WorldCamera) -> Array[int]:
	if camera == null:
		return []
	return [camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom]
