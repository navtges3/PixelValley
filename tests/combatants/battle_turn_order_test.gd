extends TestCase


func run_tests() -> int:
	_begin_test_run()
	_test_initiative_order_and_player_tie_break()
	_test_same_party_ties_preserve_membership_order()
	_test_defeated_combatants_are_skipped_and_order_cycles()
	_test_non_primary_hero_acts_and_completes_turn()
	_test_one_defeated_member_does_not_end_battle()
	_test_all_enemy_members_trigger_victory()
	_test_all_player_members_trigger_defeat()
	_test_defeated_signal_emits_once_per_member()
	return _finish_test_run("Battle turn order tests")


func _test_initiative_order_and_player_tie_break() -> void:
	var manager := BattleManager.new()
	var player := _make_combatant(10)
	var enemy := _make_combatant(10)
	var slower_enemy := _make_combatant(7)

	manager.player_party.add_member(player)
	manager.enemy_party.add_member(enemy)
	manager.enemy_party.add_member(slower_enemy)
	manager._build_turn_order()

	_expect_equal(
		manager._get_next_living_combatant(),
		player,
		"player acts first when Initiative is tied"
	)
	_expect_equal(
		manager._get_next_living_combatant(),
		enemy,
		"tied enemy acts after the player"
	)
	_expect_equal(
		manager._get_next_living_combatant(),
		slower_enemy,
		"lower Initiative acts after higher Initiative"
	)


func _test_same_party_ties_preserve_membership_order() -> void:
	var manager := BattleManager.new()
	var first_player := _make_combatant(8)
	var second_player := _make_combatant(8)
	var enemy := _make_combatant(8)

	manager.player_party.add_member(first_player)
	manager.player_party.add_member(second_player)
	manager.enemy_party.add_member(enemy)
	manager._build_turn_order()

	_expect_equal(
		manager._get_next_living_combatant(),
		first_player,
		"first player retains party order on an Initiative tie"
	)
	_expect_equal(
		manager._get_next_living_combatant(),
		second_player,
		"second player follows party order on an Initiative tie"
	)
	_expect_equal(
		manager._get_next_living_combatant(),
		enemy,
		"enemy follows tied player-party members"
	)


func _test_defeated_combatants_are_skipped_and_order_cycles() -> void:
	var manager := BattleManager.new()
	var player := _make_combatant(10)
	var defeated_enemy := _make_combatant(9)
	var slower_player := _make_combatant(5)

	manager.player_party.add_member(player)
	manager.player_party.add_member(slower_player)
	manager.enemy_party.add_member(defeated_enemy)
	manager._build_turn_order()
	defeated_enemy.current_hp = 0

	_expect_equal(
		manager._get_next_living_combatant(),
		player,
		"highest-Initiative living combatant acts first"
	)
	_expect_equal(
		manager._get_next_living_combatant(),
		slower_player,
		"defeated combatant is skipped"
	)
	_expect_equal(
		manager._get_next_living_combatant(),
		player,
		"turn order cycles after the last living combatant"
	)


func _test_non_primary_hero_acts_and_completes_turn() -> void:
	var manager := BattleManager.new()
	var primary_hero := _make_hero("Primary Hero", 30)
	var acting_hero := _make_hero("Acting Hero", 20)
	var next_hero := _make_hero("Next Hero", 10)
	var secondary_enemy := _make_monster("Secondary Enemy", 5)
	var primary_enemy := _make_monster("Primary Enemy", 1)
	var ability := _make_ability()

	manager.hero = primary_hero
	manager.monster = primary_enemy
	manager.player_party.add_member(primary_hero)
	manager.player_party.add_member(acting_hero)
	manager.player_party.add_member(next_hero)
	manager.enemy_party.add_member(secondary_enemy)
	manager.enemy_party.add_member(primary_enemy)
	manager._build_turn_order()

	manager._get_next_living_combatant()
	manager.active_combatant = manager._get_next_living_combatant()
	manager.state = BattleManager.BattleState.PLAYER_TURN
	manager._active_effects_at_turn_start = EffectManager.capture_turn_start(acting_hero)

	manager.player_ability_selected(ability)

	_expect_equal(
		acting_hero.current_nrg,
		7,
		"the active non-primary hero pays the ability energy cost"
	)
	_expect_equal(
		primary_hero.current_nrg,
		10,
		"the primary hero does not act during another hero's turn"
	)
	_expect_true(
		secondary_enemy.current_hp < secondary_enemy.max_hp,
		"the first living enemy receives the active hero's attack"
	)
	_expect_equal(
		manager.active_combatant,
		next_hero,
		"the non-primary hero's action advances to the next turn"
	)


func _test_one_defeated_member_does_not_end_battle() -> void:
	var manager := _make_party_manager(2, 2)
	var defeated_enemy := manager.enemy_party.get_members()[0] as Monster
	defeated_enemy.current_hp = 0

	manager._resolve_party_defeat()

	_expect_false(
		manager.state in [
			BattleManager.BattleState.VICTORY,
			BattleManager.BattleState.DEFEAT,
		],
		"one defeated enemy does not end a party battle"
	)


func _test_all_enemy_members_trigger_victory() -> void:
	var manager := _make_party_manager(1, 2)
	for enemy: Combatant in manager.enemy_party.get_members():
		enemy.current_hp = 0

	manager._resolve_party_defeat()

	_expect_equal(
		manager.state,
		BattleManager.BattleState.VICTORY,
		"all defeated enemies trigger victory"
	)


func _test_all_player_members_trigger_defeat() -> void:
	var manager := _make_party_manager(2, 1)
	for player: Combatant in manager.player_party.get_members():
		player.current_hp = 0

	manager._resolve_party_defeat()

	_expect_equal(
		manager.state,
		BattleManager.BattleState.DEFEAT,
		"all defeated players trigger defeat"
	)


func _test_defeated_signal_emits_once_per_member() -> void:
	var manager := _make_party_manager(2, 2)
	var defeated := manager.enemy_party.get_members()[0] as Monster
	var defeated_count := [0]
	manager.combatant_defeated.connect(
		func(_combatant: Combatant) -> void:
			defeated_count[0] += 1
	)
	defeated.current_hp = 0

	manager._emit_newly_defeated_combatants()
	manager._emit_newly_defeated_combatants()

	_expect_equal(
		defeated_count[0],
		1,
		"defeated signal emits once for each combatant"
	)


func _make_party_manager(player_count: int, enemy_count: int) -> BattleManager:
	var manager := BattleManager.new()
	for index: int in player_count:
		var hero := _make_hero("Hero %d" % index, 10 - index)
		manager.player_party.add_member(hero)
	for index: int in enemy_count:
		var monster := _make_monster("Monster %d" % index, 5 - index)
		manager.enemy_party.add_member(monster)
	manager.hero = manager.player_party.get_members()[0] as Hero
	manager.monster = manager.enemy_party.get_members()[0] as Monster
	return manager


func _make_combatant(initiative: int) -> Combatant:
	var combatant := Combatant.new()
	combatant.max_hp = 10
	combatant.current_hp = 10
	combatant.initiative = initiative
	return combatant


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
	hero.inventory = Inventory.new()
	hero.inventory.equipped_weapon = Weapon.new()
	return hero


func _make_monster(monster_name: String, initiative: int) -> Monster:
	var monster := Monster.new()
	monster.name = monster_name
	monster.max_hp = 20
	monster.current_hp = 20
	monster.max_nrg = 10
	monster.current_nrg = 10
	monster.defense = 0
	monster.resist = 0
	monster.initiative = initiative
	monster.basic_attack = Ability.new()
	return monster


func _make_ability() -> Ability:
	var ability := Ability.new()
	ability.name = "Test Strike"
	ability.energy_cost = 3
	var attack := Attack.new()
	attack.min_damage = 1
	attack.max_damage = 1
	attack.attack_type = Attack.AttackType.PHYSICAL
	ability.attack = attack
	return ability
