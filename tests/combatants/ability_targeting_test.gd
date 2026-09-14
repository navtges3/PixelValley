extends TestCase


func run_tests() -> int:
	_begin_test_run()
	_test_self_targeting()
	_test_ally_targeting()
	_test_party_targeting()
	_test_enemy_targeting()
	_test_enemy_party_targeting()
	_test_defeated_combatants_excluded()
	_test_multi_target_energy_and_cooldown_deducted_once()
	_test_multi_target_effect_duplication()
	_test_battle_manager_player_ability_multi_target()
	_test_battle_manager_friendly_buff_does_not_emit_combatant_hurt()
	return _finish_test_run("Ability targeting tests")


func _test_self_targeting() -> void:
	var ability := Ability.new()
	ability.name = "Self Focus"
	ability.target_type = Ability.TargetType.SELF
	ability.energy_cost = 2

	var caster := _make_hero("Caster", 20, 10)
	var ally := _make_hero("Teammate", 20, 10)
	var enemy := _make_monster("Enemy", 20)

	var friendly := BattleParty.new()
	friendly.add_member(caster)
	friendly.add_member(ally)

	var opposing := BattleParty.new()
	opposing.add_member(enemy)

	_expect_true(ability.is_single_target(), "SELF is single-target")
	_expect_false(ability.is_multi_target(), "SELF is not multi-target")
	_expect_true(ability.is_friendly(), "SELF is friendly")
	_expect_false(ability.is_hostile(), "SELF is not hostile")

	var valid_targets := ability.get_valid_targets(caster, friendly, opposing)
	_expect_equal(valid_targets.size(), 1, "SELF targets exactly one combatant")
	_expect_equal(valid_targets[0], caster, "SELF valid target is the caster")

	_expect_true(ability.is_valid_target(caster, caster, friendly, opposing), "caster is valid for SELF")
	_expect_false(ability.is_valid_target(caster, ally, friendly, opposing), "ally is invalid for SELF")
	_expect_false(ability.is_valid_target(caster, enemy, friendly, opposing), "enemy is invalid for SELF")

	var effect := _make_instant_heal_effect("self_heal", 5)
	ability.target_effects.append(effect)
	caster.current_hp = 10

	var output := ability.use(caster)
	_expect_true(not output.is_empty(), "ability executes on self")
	_expect_equal(caster.current_hp, 15, "caster received heal from SELF ability")
	_expect_equal(caster.current_nrg, 8, "energy deducted for SELF ability")


func _test_ally_targeting() -> void:
	var ability := Ability.new()
	ability.name = "First Aid"
	ability.target_type = Ability.TargetType.ALLY
	ability.energy_cost = 3

	var caster := _make_hero("Caster", 20, 10)
	var teammate := _make_hero("Teammate", 20, 10)
	var enemy := _make_monster("Enemy", 20)

	var friendly := BattleParty.new()
	friendly.add_member(caster)
	friendly.add_member(teammate)

	var opposing := BattleParty.new()
	opposing.add_member(enemy)

	_expect_true(ability.is_single_target(), "ALLY is single-target")
	_expect_false(ability.is_multi_target(), "ALLY is not multi-target")
	_expect_true(ability.is_friendly(), "ALLY is friendly")
	_expect_false(ability.is_hostile(), "ALLY is not hostile")

	var valid_targets := ability.get_valid_targets(caster, friendly, opposing)
	_expect_equal(valid_targets.size(), 2, "ALLY targets living friendly combatants")
	_expect_true(valid_targets.has(caster), "ALLY includes caster")
	_expect_true(valid_targets.has(teammate), "ALLY includes teammate")
	_expect_false(valid_targets.has(enemy), "ALLY excludes enemy")

	_expect_true(ability.is_valid_target(caster, teammate, friendly, opposing), "teammate is valid for ALLY")
	_expect_true(ability.is_valid_target(caster, caster, friendly, opposing), "caster is valid for ALLY")
	_expect_false(ability.is_valid_target(caster, enemy, friendly, opposing), "enemy is invalid for ALLY")

	var heal := _make_instant_heal_effect("first_aid_heal", 6)
	ability.target_effects.append(heal)
	teammate.current_hp = 10

	var output := ability.use(caster, teammate)
	_expect_true(not output.is_empty(), "ability executes on teammate")
	_expect_equal(teammate.current_hp, 16, "teammate received heal from ALLY ability")
	_expect_equal(caster.current_hp, 20, "caster HP untouched when targeting teammate")


func _test_party_targeting() -> void:
	var ability := Ability.new()
	ability.name = "Party Prayer"
	ability.target_type = Ability.TargetType.PARTY
	ability.energy_cost = 5

	var caster := _make_hero("Caster", 20, 10)
	var ally1 := _make_hero("Ally1", 20, 10)
	var ally2 := _make_hero("Ally2", 20, 10)
	var dead_ally := _make_hero("DeadAlly", 20, 10)
	dead_ally.current_hp = 0

	var friendly := BattleParty.new()
	friendly.add_member(caster)
	friendly.add_member(ally1)
	friendly.add_member(ally2)
	friendly.add_member(dead_ally)

	var enemy := _make_monster("Enemy", 20)
	var opposing := BattleParty.new()
	opposing.add_member(enemy)

	_expect_false(ability.is_single_target(), "PARTY is not single-target")
	_expect_true(ability.is_multi_target(), "PARTY is multi-target")
	_expect_true(ability.is_friendly(), "PARTY is friendly")

	var valid_targets := ability.get_valid_targets(caster, friendly, opposing)
	_expect_equal(valid_targets.size(), 3, "PARTY targets all living friendly members")
	_expect_true(valid_targets.has(caster), "PARTY includes caster")
	_expect_true(valid_targets.has(ally1), "PARTY includes living ally1")
	_expect_true(valid_targets.has(ally2), "PARTY includes living ally2")
	_expect_false(valid_targets.has(dead_ally), "PARTY excludes defeated ally")
	_expect_false(valid_targets.has(enemy), "PARTY excludes enemy")

	var heal := _make_instant_heal_effect("party_heal", 4)
	ability.target_effects.append(heal)
	caster.current_hp = 10
	ally1.current_hp = 12
	ally2.current_hp = 14

	var output := ability.use_on_targets(caster, valid_targets)
	_expect_true(not output.is_empty(), "ability executes on entire party")
	_expect_equal(caster.current_hp, 14, "caster received party heal")
	_expect_equal(ally1.current_hp, 16, "ally1 received party heal")
	_expect_equal(ally2.current_hp, 18, "ally2 received party heal")
	_expect_equal(dead_ally.current_hp, 0, "dead ally was not healed")
	_expect_equal(caster.current_nrg, 5, "energy cost deducted only once for PARTY")


func _test_enemy_targeting() -> void:
	var ability := Ability.new()
	ability.name = "Single Strike"
	ability.target_type = Ability.TargetType.ENEMY
	ability.energy_cost = 2
	ability.attack = _make_attack(5, 5)

	var caster := _make_hero("Caster", 20, 10)
	var enemy1 := _make_monster("Enemy1", 20)
	var enemy2 := _make_monster("Enemy2", 20)

	var friendly := BattleParty.new()
	friendly.add_member(caster)

	var opposing := BattleParty.new()
	opposing.add_member(enemy1)
	opposing.add_member(enemy2)

	_expect_true(ability.is_single_target(), "ENEMY is single-target")
	_expect_false(ability.is_multi_target(), "ENEMY is not multi-target")
	_expect_true(ability.is_hostile(), "ENEMY is hostile")
	_expect_false(ability.is_friendly(), "ENEMY is not friendly")

	var valid_targets := ability.get_valid_targets(caster, friendly, opposing)
	_expect_equal(valid_targets.size(), 2, "ENEMY targets living opposing combatants")
	_expect_true(valid_targets.has(enemy1), "ENEMY includes enemy1")
	_expect_true(valid_targets.has(enemy2), "ENEMY includes enemy2")
	_expect_false(valid_targets.has(caster), "ENEMY excludes caster")

	_expect_true(ability.is_valid_target(caster, enemy1, friendly, opposing), "enemy1 is valid")
	_expect_false(ability.is_valid_target(caster, caster, friendly, opposing), "caster is invalid for ENEMY")

	var output := ability.use(caster, enemy1)
	_expect_true(not output.is_empty(), "ability hits enemy1")
	_expect_equal(enemy1.current_hp, 15, "enemy1 took damage")
	_expect_equal(enemy2.current_hp, 20, "enemy2 took no damage")


func _test_enemy_party_targeting() -> void:
	var ability := Ability.new()
	ability.name = "Meteor Rain"
	ability.target_type = Ability.TargetType.ENEMY_PARTY
	ability.energy_cost = 4
	ability.attack = _make_attack(6, 6)

	var caster := _make_hero("Caster", 20, 10)
	var enemy1 := _make_monster("Enemy1", 20)
	var enemy2 := _make_monster("Enemy2", 20)
	var dead_enemy := _make_monster("DeadEnemy", 20)
	dead_enemy.current_hp = 0

	var friendly := BattleParty.new()
	friendly.add_member(caster)

	var opposing := BattleParty.new()
	opposing.add_member(enemy1)
	opposing.add_member(enemy2)
	opposing.add_member(dead_enemy)

	_expect_false(ability.is_single_target(), "ENEMY_PARTY is not single-target")
	_expect_true(ability.is_multi_target(), "ENEMY_PARTY is multi-target")
	_expect_true(ability.is_hostile(), "ENEMY_PARTY is hostile")

	var valid_targets := ability.get_valid_targets(caster, friendly, opposing)
	_expect_equal(valid_targets.size(), 2, "ENEMY_PARTY targets only living enemies")
	_expect_true(valid_targets.has(enemy1), "ENEMY_PARTY includes enemy1")
	_expect_true(valid_targets.has(enemy2), "ENEMY_PARTY includes enemy2")
	_expect_false(valid_targets.has(dead_enemy), "ENEMY_PARTY excludes dead enemy")

	var output := ability.use_on_targets(caster, valid_targets)
	_expect_true(not output.is_empty(), "ability hits all living enemies")
	_expect_equal(enemy1.current_hp, 14, "enemy1 took damage")
	_expect_equal(enemy2.current_hp, 14, "enemy2 took damage")
	_expect_equal(caster.current_nrg, 6, "caster energy deducted once for ENEMY_PARTY")


func _test_defeated_combatants_excluded() -> void:
	var ability := Ability.new()
	ability.name = "Strike"
	ability.target_type = Ability.TargetType.ENEMY
	ability.energy_cost = 3
	ability.attack = _make_attack(4, 4)

	var caster := _make_hero("Caster", 20, 10)
	var dead_enemy := _make_monster("DeadEnemy", 20)
	dead_enemy.current_hp = 0

	var friendly := BattleParty.new()
	friendly.add_member(caster)

	var opposing := BattleParty.new()
	opposing.add_member(dead_enemy)

	_expect_false(ability.is_valid_target(caster, dead_enemy, friendly, opposing), "defeated target is rejected")
	_expect_false(ability.is_valid_target(caster, null, friendly, opposing), "null target is rejected")

	var valid_targets := ability.get_valid_targets(caster, friendly, opposing)
	_expect_equal(valid_targets.size(), 0, "no valid targets when all enemies are defeated")

	var output := ability.use(caster, dead_enemy)
	_expect_true(output.is_empty(), "ability fails to execute on defeated target")
	_expect_equal(caster.current_nrg, 10, "energy is not consumed on failed execution")

	caster.current_hp = 0
	_expect_false(ability.is_ready(caster, dead_enemy), "defeated caster is not ready")
	_expect_equal(ability.get_valid_targets(caster, friendly, opposing).size(), 0, "defeated caster has no valid targets")


func _test_multi_target_energy_and_cooldown_deducted_once() -> void:
	var ability := Ability.new()
	ability.name = "Cleave"
	ability.target_type = Ability.TargetType.ENEMY_PARTY
	ability.energy_cost = 4
	ability.cooldown = 2
	ability.attack = _make_attack(2, 2)

	var caster := _make_hero("Caster", 20, 10)
	var targets: Array[Combatant] = [
		_make_monster("E1", 20),
		_make_monster("E2", 20),
		_make_monster("E3", 20),
	]

	var output := ability.use_on_targets(caster, targets)
	_expect_true(not output.is_empty(), "cleave executed")
	_expect_equal(caster.current_nrg, 6, "energy deducted exactly once (10 - 4 = 6)")
	_expect_equal(ability.current_cooldown, 3, "cooldown set to cooldown + 1 exactly once")


func _test_multi_target_effect_duplication() -> void:
	var ability := Ability.new()
	ability.name = "Party Shield"
	ability.target_type = Ability.TargetType.PARTY
	ability.energy_cost = 2

	var buff := Effect.new()
	buff.effect_id = &"defense_buff"
	buff.effect_name = "Defense Buff"
	buff.base_duration = 3
	buff.is_instant = false

	var stat_change := EffectStatChange.new()
	stat_change.stat = Effect.EffectStat.DEFENSE
	stat_change.timing = Effect.EffectTiming.ON_APPLY
	stat_change.operation = Effect.EffectOperation.ADD
	stat_change.base_amount = 5
	buff.stat_changes.append(stat_change)

	ability.target_effects.append(buff)

	var caster := _make_hero("Caster", 20, 10)
	var ally := _make_hero("Ally", 20, 10)
	var targets: Array[Combatant] = [caster, ally]

	ability.use_on_targets(caster, targets)

	_expect_equal(caster.defense, 5, "caster received defense buff")
	_expect_equal(ally.defense, 5, "ally received defense buff")
	_expect_equal(caster.active_effects.size(), 1, "caster has active effect")
	_expect_equal(ally.active_effects.size(), 1, "ally has active effect")
	_expect_true(
		caster.active_effects[0].effect != ally.active_effects[0].effect,
		"effects applied to different combatants are duplicated independent instances"
	)


func _test_battle_manager_player_ability_multi_target() -> void:
	var manager := BattleManager.new()
	var hero1 := _make_hero("Hero1", 20, 10)
	var enemy1 := _make_monster("Enemy1", 20)
	var enemy2 := _make_monster("Enemy2", 20)

	manager.player_party.add_member(hero1)
	manager.enemy_party.add_member(enemy1)
	manager.enemy_party.add_member(enemy2)
	manager.hero = hero1
	manager.monster = enemy1
	manager.active_combatant = hero1
	manager.state = BattleManager.BattleState.PLAYER_TURN
	manager._build_turn_order()

	var aoe := Ability.new()
	aoe.name = "Arcane Burst"
	aoe.target_type = Ability.TargetType.ENEMY_PARTY
	aoe.energy_cost = 4
	aoe.attack = _make_attack(7, 7)

	var hurt_combatants: Array[Combatant] = []
	manager.combatant_hurt.connect(func(c: Combatant) -> void: hurt_combatants.append(c))

	manager.player_ability_selected(aoe)

	_expect_equal(enemy1.current_hp, 13, "enemy1 took damage from player ability")
	_expect_equal(enemy2.current_hp, 13, "enemy2 took damage from player ability")
	_expect_equal(hurt_combatants.size(), 2, "combatant_hurt emitted for each damaged enemy")
	_expect_true(hurt_combatants.has(enemy1), "enemy1 received hurt signal")
	_expect_true(hurt_combatants.has(enemy2), "enemy2 received hurt signal")


func _test_battle_manager_friendly_buff_does_not_emit_combatant_hurt() -> void:
	var manager := BattleManager.new()
	var hero1 := _make_hero("Hero1", 20, 10)
	var hero2 := _make_hero("Hero2", 20, 10)
	var enemy := _make_monster("Enemy", 20)

	manager.player_party.add_member(hero1)
	manager.player_party.add_member(hero2)
	manager.enemy_party.add_member(enemy)
	manager.hero = hero1
	manager.monster = enemy
	manager.active_combatant = hero1
	manager.state = BattleManager.BattleState.PLAYER_TURN
	manager._build_turn_order()

	var buff_ability := Ability.new()
	buff_ability.name = "Blessing"
	buff_ability.target_type = Ability.TargetType.PARTY
	buff_ability.energy_cost = 2
	buff_ability.target_effects.append(_make_instant_heal_effect("blessing_heal", 3))

	var hurt_emitted := false
	manager.combatant_hurt.connect(func(_c: Combatant) -> void: hurt_emitted = true)

	manager.player_ability_selected(buff_ability)

	_expect_false(hurt_emitted, "combatant_hurt is not emitted when using friendly buff")


func _make_hero(hero_name: String, hp: int, energy: int) -> Hero:
	var hero := Hero.new()
	hero.name = hero_name
	hero.max_hp = hp
	hero.current_hp = hp
	hero.max_nrg = energy
	hero.current_nrg = energy
	hero.attack = 0
	hero.magic = 0
	hero.defense = 0
	hero.resist = 0
	hero.initiative = 10
	hero.equipped_weapon = Weapon.new()
	return hero


func _make_monster(monster_name: String, hp: int) -> Monster:
	var monster := Monster.new()
	monster.name = monster_name
	monster.max_hp = hp
	monster.current_hp = hp
	monster.max_nrg = 10
	monster.current_nrg = 10
	monster.attack = 0
	monster.magic = 0
	monster.defense = 0
	monster.resist = 0
	monster.initiative = 5
	monster.basic_attack = Ability.new()
	return monster


func _make_attack(min_dmg: int, max_dmg: int) -> Attack:
	var attack := Attack.new()
	attack.min_damage = min_dmg
	attack.max_damage = max_dmg
	attack.attack_type = Attack.AttackType.PHYSICAL
	return attack


func _make_instant_heal_effect(effect_id: String, amount: int) -> Effect:
	var effect := Effect.new()
	effect.effect_id = StringName(effect_id)
	effect.effect_name = effect_id
	effect.is_instant = true
	var stat := EffectStatChange.new()
	stat.stat = Effect.EffectStat.CURRENT_HP
	stat.timing = Effect.EffectTiming.ON_APPLY
	stat.operation = Effect.EffectOperation.ADD
	stat.base_amount = amount
	effect.stat_changes.append(stat)
	return effect
