extends TestCase


func run_tests() -> int:
	_begin_test_run()
	_test_initiative_order_and_player_tie_break()
	_test_same_party_ties_preserve_membership_order()
	_test_defeated_combatants_are_skipped_and_order_cycles()
	_test_non_primary_hero_acts_and_completes_turn()
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
