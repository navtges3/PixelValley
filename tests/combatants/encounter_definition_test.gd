extends TestCase


func run_tests() -> int:
	_begin_test_run()
	_test_empty_encounter_returns_empty_party()
	_test_single_monster_encounter()
	_test_multi_monster_encounter_counts_and_types()
	_test_capacity_limit_clamping()
	_test_duplicate_monsters_are_distinct_instances()
	_test_lead_monster_id_and_world_visual()
	_test_battle_manager_setup_battle_with_encounter()
	_test_battle_manager_setup_battle_legacy_fallback()
	_test_spawn_point_assigns_encounter_to_enemy()
	_test_world_spawner_defeat_tracking_integration()
	_test_development_encounter_resources_load_and_instantiate()
	return _finish_test_run("Encounter definition tests")


func _test_empty_encounter_returns_empty_party() -> void:
	var encounter := EncounterDefinition.new()
	var party := encounter.create_enemy_party()
	_expect_equal(party.get_members().size(), 0, "empty encounter creates empty party")


func _test_single_monster_encounter() -> void:
	var encounter := EncounterDefinition.new()
	encounter.monster_ids = [MonsterLoader.MonsterID.GOBLIN]
	var party := encounter.create_enemy_party()
	_expect_equal(party.get_members().size(), 1, "single monster encounter creates 1-member party")
	_expect_true(party.has_living_members(), "single monster is alive")


func _test_multi_monster_encounter_counts_and_types() -> void:
	var encounter_duo := EncounterDefinition.new()
	encounter_duo.monster_ids = [MonsterLoader.MonsterID.GOBLIN, MonsterLoader.MonsterID.GOBLIN]
	var party_duo := encounter_duo.create_enemy_party()
	_expect_equal(party_duo.get_members().size(), 2, "duo encounter creates 2 members")

	var encounter_mixed := EncounterDefinition.new()
	encounter_mixed.monster_ids = [
		MonsterLoader.MonsterID.GOBLIN,
		MonsterLoader.MonsterID.ORC,
		MonsterLoader.MonsterID.ORC_CHIEFTAIN,
	]
	var party_mixed := encounter_mixed.create_enemy_party()
	_expect_equal(party_mixed.get_members().size(), 3, "mixed encounter creates 3 members")
	var members := party_mixed.get_members()
	_expect_equal((members[0] as Monster).monster_id, MonsterLoader.MonsterID.GOBLIN, "first member is goblin")
	_expect_equal((members[1] as Monster).monster_id, MonsterLoader.MonsterID.ORC, "second member is orc")
	_expect_equal((members[2] as Monster).monster_id, MonsterLoader.MonsterID.ORC_CHIEFTAIN, "third member is orc chieftain")


func _test_capacity_limit_clamping() -> void:
	var encounter := EncounterDefinition.new()
	encounter.monster_ids = [
		MonsterLoader.MonsterID.GOBLIN,
		MonsterLoader.MonsterID.GOBLIN,
		MonsterLoader.MonsterID.GOBLIN,
		MonsterLoader.MonsterID.GOBLIN,
		MonsterLoader.MonsterID.GOBLIN,
		MonsterLoader.MonsterID.GOBLIN,
	]
	var party := encounter.create_enemy_party()
	_expect_equal(party.get_members().size(), EncounterDefinition.MAX_ENEMIES, "party size clamped to MAX_ENEMIES")


func _test_duplicate_monsters_are_distinct_instances() -> void:
	var encounter := EncounterDefinition.new()
	encounter.monster_ids = [MonsterLoader.MonsterID.GOBLIN, MonsterLoader.MonsterID.GOBLIN]
	var party := encounter.create_enemy_party()
	var m1 := party.get_members()[0] as Monster
	var m2 := party.get_members()[1] as Monster
	_expect_true(m1 != m2, "monsters of same type are distinct instances")
	m1.current_hp = 1
	_expect_equal(m1.current_hp, 1, "m1 hp modified")
	_expect_equal(m2.current_hp, m2.max_hp, "m2 hp unchanged")


func _test_lead_monster_id_and_world_visual() -> void:
	var encounter := EncounterDefinition.new()
	encounter.monster_ids = [MonsterLoader.MonsterID.ORC, MonsterLoader.MonsterID.GOBLIN]
	_expect_equal(encounter.get_lead_monster_id(), MonsterLoader.MonsterID.ORC, "lead monster ID is first monster")
	var visual := encounter.get_lead_world_visual()
	_expect_not_null(visual, "lead monster world visual is available")


func _test_battle_manager_setup_battle_with_encounter() -> void:
	var manager := BattleManager.new()
	var hero := _make_hero("Hero", 10)
	var party := Party.new()
	party.add_member(hero)

	var encounter := EncounterDefinition.new()
	encounter.monster_ids = [
		MonsterLoader.MonsterID.GOBLIN,
		MonsterLoader.MonsterID.ORC,
		MonsterLoader.MonsterID.GOBLIN,
	]
	manager.setup_battle({
		"hero": hero,
		"persistent_party": party,
		"encounter": encounter,
	})
	_expect_equal(manager.enemy_party.get_members().size(), 3, "BattleManager created 3-enemy party from encounter")
	_expect_equal(manager.monster, manager.enemy_party.get_members()[0], "BattleManager.monster is first encounter enemy")
	_expect_equal(manager.hero, hero, "BattleManager.hero is active hero")


func _test_battle_manager_setup_battle_legacy_fallback() -> void:
	var manager := BattleManager.new()
	var hero := _make_hero("Hero", 10)
	var party := Party.new()
	party.add_member(hero)

	manager.setup_battle({
		"hero": hero,
		"persistent_party": party,
		"monster_id": MonsterLoader.MonsterID.ORC,
	})
	_expect_equal(manager.enemy_party.get_members().size(), 1, "BattleManager creates 1 enemy on legacy fallback")
	_expect_equal((manager.enemy_party.get_members()[0] as Monster).monster_id, MonsterLoader.MonsterID.ORC, "legacy monster is ORC")


func _test_spawn_point_assigns_encounter_to_enemy() -> void:
	var spawner := SpawnPoint.new()
	var encounter := EncounterDefinition.new()
	encounter.monster_ids = [MonsterLoader.MonsterID.ORC, MonsterLoader.MonsterID.GOBLIN]
	spawner.encounter = encounter

	var parent_node := Node2D.new()
	add_child(parent_node)
	# SpawnPoint must be in the scene tree before spawn() so that get_path() succeeds.
	parent_node.add_child(spawner)
	spawner.spawn(parent_node, func(_e): pass, "test_loc")

	_expect_equal(spawner.spawned_enemies.size(), 1, "SpawnPoint spawned 1 enemy for encounter")
	var enemy := spawner.spawned_enemies[0]
	_expect_equal(enemy.encounter, encounter, "Enemy has encounter assigned")
	_expect_equal(enemy.monster_id, MonsterLoader.MonsterID.ORC, "Enemy monster_id matches lead monster")

	# parent_node.queue_free() also frees spawner and its spawned enemies transitively.
	parent_node.queue_free()


func _test_world_spawner_defeat_tracking_integration() -> void:
	var loc_id := "test_encounter_loc"
	var spawner_path := "/root/TestSpawner"
	WorldManager.reset_location_spawners(loc_id)
	_expect_false(WorldManager.is_spawner_defeated(loc_id, spawner_path), "spawner starts undefeated")

	var manager := BattleManager.new()
	var hero := _make_hero("Hero", 10)
	var party := Party.new()
	party.add_member(hero)
	var encounter := EncounterDefinition.new()
	encounter.monster_ids = [MonsterLoader.MonsterID.GOBLIN, MonsterLoader.MonsterID.GOBLIN]
	manager.setup_battle({
		"hero": hero,
		"persistent_party": party,
		"encounter": encounter,
		"location_id": loc_id,
		"spawn_point_id": spawner_path,
	})
	manager.end_battle(true)
	_expect_true(WorldManager.is_spawner_defeated(loc_id, spawner_path), "winning encounter battle marks spawner defeated")


func _test_development_encounter_resources_load_and_instantiate() -> void:
	var duo := load("res://resources/encounters/dev_goblin_duo.tres") as EncounterDefinition
	_expect_not_null(duo, "dev_goblin_duo.tres loads")
	_expect_equal(duo.create_enemy_party().get_members().size(), 2, "dev_goblin_duo creates 2 enemies")

	var trio := load("res://resources/encounters/dev_forest_pack.tres") as EncounterDefinition
	_expect_not_null(trio, "dev_forest_pack.tres loads")
	_expect_equal(trio.create_enemy_party().get_members().size(), 3, "dev_forest_pack creates 3 enemies")

	var quad := load("res://resources/encounters/dev_orc_squad.tres") as EncounterDefinition
	_expect_not_null(quad, "dev_orc_squad.tres loads")
	_expect_equal(quad.create_enemy_party().get_members().size(), 4, "dev_orc_squad creates 4 enemies")


func _make_hero(hero_name: String, initiative: int) -> Hero:
	var hero := Hero.new()
	hero.name = hero_name
	hero.max_hp = 20
	hero.current_hp = 20
	hero.max_nrg = 10
	hero.current_nrg = 10
	hero.attack = 2
	hero.defense = 0
	hero.resist = 0
	hero.initiative = initiative
	hero.equipped_weapon = Weapon.new()
	return hero
