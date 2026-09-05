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

	# Instantiate Game scene
	var game := GAME_SCENE.instantiate() as Game
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	while ScreenManager.is_transitioning():
		await get_tree().process_frame
	await get_tree().process_frame

	_expect_not_null(Game.get_instance(), "Game instance should be registered")
	_expect_not_null(Game.get_player(), "Game should have persistent player")
	_expect_not_null(Game.get_world(), "Game should have persistent world")

	var player := Game.get_player()
	var initial_player_id := player.get_instance_id()

	# 1. Transition to Village
	ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE)
	while ScreenManager.is_transitioning():
		await get_tree().process_frame
	await get_tree().process_frame

	var village := Game.get_current_location() as VillageLocation
	_expect_not_null(village, "Village should be loaded as current location")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance ID should not change in Village")
	_expect_true(player.get_parent() == village.y_sorted_world, "Player should be reparented to Village YSortedWorld")
	_expect_true(player.visible, "Player should be visible in Village")
	_expect_true(player.is_in_group("player"), "Player should remain in 'player' group")
	_expect_equal(player.global_position, VillageLocation.DEFAULT_SPAWN_POSITION, "Player should be at Village default spawn")
	_expect_equal(GameState.player_location["scene"], ScreenManager.ScreenName.VILLAGE, "GameState should track Village")

	# 2. Transition to Valley from Village
	ScreenManager.go_to_screen(ScreenManager.ScreenName.VALLEY, "village")
	while ScreenManager.is_transitioning():
		await get_tree().process_frame
	await get_tree().process_frame

	var valley := Game.get_current_location() as ValleyLocation
	_expect_not_null(valley, "Valley should be loaded as current location")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance ID should not change in Valley")
	_expect_true(player.get_parent() == valley.y_sorted_world, "Player should be reparented to Valley YSortedWorld")
	_expect_equal(GameState.player_location["scene"], ScreenManager.ScreenName.VALLEY, "GameState should track Valley")
	_expect_equal(GameState.player_location["entrance_id"], "village", "GameState entrance should be village")

	# 3. Transition to Forest
	ScreenManager.go_to_screen(ScreenManager.ScreenName.FOREST, "forest")
	while ScreenManager.is_transitioning():
		await get_tree().process_frame
	await get_tree().process_frame

	var forest := Game.get_current_location() as ForestLocation
	_expect_not_null(forest, "Forest should be loaded as current location")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance ID should not change in Forest")
	_expect_true(player.get_parent() == forest.y_sorted_world, "Player should be reparented to Forest YSortedWorld")

	# 4. Enter Battle
	var battle_pos := Vector2(200, 300)
	player.global_position = battle_pos
	GameState.pre_combat_position = battle_pos
	ScreenManager.go_to_screen(ScreenManager.ScreenName.BATTLE, "", {
		"hero": HeroLoader.new_hero(Hero.HeroClass.KNIGHT),
		"monster_id": MonsterLoader.MonsterID.GOBLIN,
	})
	while ScreenManager.is_transitioning():
		await get_tree().process_frame
	await get_tree().process_frame

	_expect_null(Game.get_current_location(), "Current location should be null during Battle")
	_expect_not_null(Game.get_current_ui(), "BattleScreen should be active UI")
	_expect_true(Game.get_current_ui() is BattleScreen, "Current UI should be BattleScreen")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance ID should not change in Battle")
	_expect_true(player.get_parent() == game, "Player should be reparented to Game root during Battle")
	_expect_true(not player.visible, "Player should be hidden during Battle")

	# 5. Return from Battle (go_back)
	ScreenManager.go_back()
	while ScreenManager.is_transitioning():
		await get_tree().process_frame
	await get_tree().process_frame

	forest = Game.get_current_location() as ForestLocation
	_expect_not_null(forest, "Forest should be restored after returning from Battle")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance ID should not change on Battle return")
	_expect_true(player.get_parent() == forest.y_sorted_world, "Player should be reparented to Forest YSortedWorld")
	_expect_true(player.visible, "Player should be visible again after Battle")
	_expect_equal(player.global_position, battle_pos, "Player position should be restored from pre_combat_position")
	_expect_equal(GameState.pre_combat_position, Vector2.ZERO, "pre_combat_position should be reset after restore")

	# 6. Transition to Inn Interior
	ScreenManager.go_to_screen(ScreenManager.ScreenName.INN, "inn")
	while ScreenManager.is_transitioning():
		await get_tree().process_frame
	await get_tree().process_frame

	var inn := Game.get_current_location() as InnInterior
	_expect_not_null(inn, "Inn interior should be loaded as current location")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance ID should not change in Inn")
	_expect_true(player.get_parent() == inn.y_sorted_world, "Player should be reparented to Inn YSortedWorld")

	# 7. Return to Main Menu
	ScreenManager.go_to_screen(ScreenManager.ScreenName.MAIN_MENU)
	while ScreenManager.is_transitioning():
		await get_tree().process_frame
	await get_tree().process_frame

	_expect_null(Game.get_current_location(), "Current location should be null at Main Menu")
	_expect_not_null(Game.get_current_ui(), "Main Menu should be active UI")
	_expect_true(Game.get_current_ui() is MainMenuScreen, "Current UI should be MainMenuScreen")
	_expect_equal(player.get_instance_id(), initial_player_id, "Player instance ID should not change at Main Menu")
	_expect_true(player.get_parent() == game, "Player should be reparented to Game root at Main Menu")
	_expect_true(not player.visible, "Player should be hidden at Main Menu")

	game.queue_free()
	await get_tree().process_frame

	return _finish_test_run("Persistent Player Architecture")

func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failures += 1
	printerr("FAIL: %s (expected %s, got %s)" % [message, expected, actual])
