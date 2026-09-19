extends TestCase


func run_tests() -> int:
	_begin_test_run()
	_test_never_targets_defeated()
	_test_prefers_low_hp()
	_test_multiple_wounded_prefers_lowest_ratio()
	_test_low_hp_tie_uses_party_order()
	_test_low_hp_boundary_is_inclusive()
	_test_healthy_party_uses_random_fallback()
	_test_seeded_repeatability()
	_test_caster_condition()
	_test_conditional_ability_ordering()
	_test_insufficient_energy_skips_ability()
	_test_cooldown_skips_ability()
	_test_multi_target_returns_null_target()
	_test_support_targets_most_injured_ally()
	_test_support_skipped_when_party_is_healthy()
	_test_support_target_condition_filters_candidates()
	_test_null_cases()
	_test_battle_manager_resolves_ai_target()
	return _finish_test_run("Enemy AI tests")


func _test_never_targets_defeated() -> void:
	var actor := _make_monster("Enemy", 20)
	var heroes := [
		_make_hero("Hero A", 20),
		_make_hero("Hero B", 20),
		_make_hero("Defeated Hero", 20),
	]
	heroes[2].current_hp = 0
	var friendly := _make_party([actor])
	var opposition := _make_party(heroes)
	var ai := EnemyAI.new(1)

	for iteration in 100:
		var decision := ai.choose_action(actor, friendly, opposition)
		_expect_not_null(decision, "living opposition produces a decision")
		if decision != null:
			_expect_false(
				decision.target == heroes[2],
				"defeated opposition is never selected",
			)


func _test_prefers_low_hp() -> void:
	var actor := _make_monster("Enemy", 20)
	var healthy := _make_hero("Healthy", 20)
	var wounded := _make_hero("Wounded", 20)
	wounded.current_hp = 4

	var decision := EnemyAI.new(1).choose_action(
		actor,
		_make_party([actor]),
		_make_party([healthy, wounded]),
	)
	_expect_not_null(decision, "wounded opposition produces a decision")
	if decision != null:
		_expect_equal(decision.target, wounded, "lowest-HP opposition is preferred")


func _test_multiple_wounded_prefers_lowest_ratio() -> void:
	var actor := _make_monster("Enemy", 20)
	var wounded_eight := _make_hero("Wounded Eight", 20)
	wounded_eight.current_hp = 8
	var wounded_four := _make_hero("Wounded Four", 20)
	wounded_four.current_hp = 4

	var decision := EnemyAI.new(1).choose_action(
		actor,
		_make_party([actor]),
		_make_party([wounded_eight, wounded_four]),
	)
	_expect_not_null(decision, "wounded opposition produces a decision")
	if decision != null:
		_expect_equal(decision.target, wounded_four, "lowest wounded ratio is preferred")


func _test_low_hp_tie_uses_party_order() -> void:
	var actor := _make_monster("Enemy", 20)
	var first := _make_hero("First", 20)
	first.current_hp = 4
	var second := _make_hero("Second", 20)
	second.current_hp = 4

	var decision := EnemyAI.new(1).choose_action(
		actor,
		_make_party([actor]),
		_make_party([first, second]),
	)
	_expect_not_null(decision, "tied wounded opposition produces a decision")
	if decision != null:
		_expect_equal(decision.target, first, "low-HP ties use party order")


func _test_low_hp_boundary_is_inclusive() -> void:
	var actor := _make_monster("Enemy", 20)
	var boundary := _make_hero("Boundary", 20)
	boundary.current_hp = 10
	var healthy := _make_hero("Healthy", 20)

	var decision := EnemyAI.new(1).choose_action(
		actor,
		_make_party([actor]),
		_make_party([boundary, healthy]),
	)
	_expect_not_null(decision, "boundary opposition produces a decision")
	if decision != null:
		_expect_equal(decision.target, boundary, "exactly half health is low HP")


func _test_healthy_party_uses_random_fallback() -> void:
	var actor := _make_monster("Enemy", 20)
	var heroes := [
		_make_hero("Hero A", 20),
		_make_hero("Hero B", 20),
		_make_hero("Hero C", 20),
	]
	var ai := EnemyAI.new(1)
	var chosen := {}

	for iteration in 100:
		var decision := ai.choose_action(actor, _make_party([actor]), _make_party(heroes))
		_expect_not_null(decision, "healthy opposition produces a random decision")
		if decision != null:
			chosen[decision.target] = true

	for hero: Hero in heroes:
		_expect_true(chosen.has(hero), "seeded fallback eventually chooses %s" % hero.name)


func _test_seeded_repeatability() -> void:
	var actor := _make_monster("Enemy", 20)
	var heroes := [
		_make_hero("Hero A", 20),
		_make_hero("Hero B", 20),
		_make_hero("Hero C", 20),
	]
	var friendly := _make_party([actor])
	var opposition := _make_party(heroes)
	var first_ai := EnemyAI.new(42)
	var second_ai := EnemyAI.new(42)

	for iteration in 10:
		var first_decision := first_ai.choose_action(actor, friendly, opposition)
		var second_decision := second_ai.choose_action(actor, friendly, opposition)
		_expect_not_null(first_decision, "first seeded AI produces a decision")
		_expect_not_null(second_decision, "second seeded AI produces a decision")
		if first_decision != null and second_decision != null:
			_expect_equal(
				first_decision.target,
				second_decision.target,
				"same seed produces the same target sequence",
			)


func _test_caster_condition() -> void:
	var actor := _make_monster("Enemy", 20)
	var conditional := _make_self_ability()
	conditional.condition = _make_health_condition(
		Condition.ConditionsSubject.CASTER,
	)
	actor.conditional_abilities.append(conditional)

	actor.current_hp = 8
	var decision := EnemyAI.new(1).choose_action(
		actor,
		_make_party([actor]),
		_make_party([_make_hero("Hero", 20)]),
	)
	_expect_not_null(decision, "caster condition produces a decision")
	if decision != null:
		_expect_equal(decision.ability, conditional, "ready caster condition is chosen")
		_expect_null(decision.target, "SELF decision has no explicit target")

	actor.current_hp = 20
	decision = EnemyAI.new(1).choose_action(
		actor,
		_make_party([actor]),
		_make_party([_make_hero("Hero", 20)]),
	)
	_expect_not_null(decision, "basic attack remains available")
	if decision != null:
		_expect_equal(decision.ability, actor.basic_attack, "failed condition falls back")


func _test_conditional_ability_ordering() -> void:
	var actor := _make_monster("Enemy", 20)
	var first := _make_self_ability()
	first.name = "First Conditional"
	var second := _make_self_ability()
	second.name = "Second Conditional"
	actor.conditional_abilities = [first, second]

	var decision := EnemyAI.new(1).choose_action(
		actor,
		_make_party([actor]),
		_make_party([_make_hero("Hero", 20)]),
	)
	_expect_not_null(decision, "ready conditional abilities produce a decision")
	if decision != null:
		_expect_equal(decision.ability, first, "conditional abilities use array order")


func _test_insufficient_energy_skips_ability() -> void:
	var actor := _make_monster("Enemy", 20)
	var expensive := _make_self_ability()
	expensive.energy_cost = 99
	actor.conditional_abilities.append(expensive)

	var decision := EnemyAI.new(1).choose_action(
		actor,
		_make_party([actor]),
		_make_party([_make_hero("Hero", 20)]),
	)
	_expect_not_null(decision, "basic attack remains usable")
	if decision != null:
		_expect_equal(decision.ability, actor.basic_attack, "insufficient energy skips ability")


func _test_cooldown_skips_ability() -> void:
	var actor := _make_monster("Enemy", 20)
	var cooling_down := _make_self_ability()
	cooling_down.current_cooldown = 2
	actor.conditional_abilities.append(cooling_down)

	var decision := EnemyAI.new(1).choose_action(
		actor,
		_make_party([actor]),
		_make_party([_make_hero("Hero", 20)]),
	)
	_expect_not_null(decision, "basic attack remains usable")
	if decision != null:
		_expect_equal(decision.ability, actor.basic_attack, "cooldown skips ability")


func _test_multi_target_returns_null_target() -> void:
	var actor := _make_monster("Enemy", 20)
	var ability := Ability.new()
	ability.name = "Enemy Party Attack"
	ability.target_type = Ability.TargetType.ENEMY_PARTY
	actor.conditional_abilities.append(ability)

	var decision := EnemyAI.new(1).choose_action(
		actor,
		_make_party([actor]),
		_make_party([_make_hero("Hero", 20)]),
	)
	_expect_not_null(decision, "multi-target ability produces a decision")
	if decision != null:
		_expect_equal(decision.ability, ability, "multi-target ability is chosen")
		_expect_null(decision.target, "multi-target decision has no explicit target")


func _test_support_targets_most_injured_ally() -> void:
	var actor := _make_monster("Healer", 20)
	var injured := _make_hero("Most Injured", 20)
	injured.current_hp = 5
	var less_injured := _make_hero("Less Injured", 20)
	less_injured.current_hp = 15
	var support := _make_ally_ability()
	actor.conditional_abilities.append(support)

	var decision := EnemyAI.new(1).choose_action(
		actor,
		_make_party([actor, injured, less_injured]),
		_make_party([_make_hero("Enemy", 20)]),
	)
	_expect_not_null(decision, "injured ally produces a support decision")
	if decision != null:
		_expect_equal(decision.ability, support, "support ability is chosen")
		_expect_equal(decision.target, injured, "most injured ally is selected")


func _test_support_skipped_when_party_is_healthy() -> void:
	var actor := _make_monster("Healer", 20)
	var support := _make_ally_ability()
	actor.conditional_abilities.append(support)

	var decision := EnemyAI.new(1).choose_action(
		actor,
		_make_party([actor, _make_hero("Ally", 20)]),
		_make_party([_make_hero("Enemy", 20)]),
	)
	_expect_not_null(decision, "basic attack remains available")
	if decision != null:
		_expect_equal(decision.ability, actor.basic_attack, "support skips a healthy party")


func _test_support_target_condition_filters_candidates() -> void:
	var actor := _make_monster("Healer", 20)
	var support := _make_ally_ability()
	support.condition = _make_health_condition(Condition.ConditionsSubject.TARGET)
	actor.conditional_abilities.append(support)
	var above_threshold := _make_hero("Above Threshold", 20)
	above_threshold.current_hp = 12
	var below_threshold := _make_hero("Below Threshold", 20)
	below_threshold.current_hp = 6
	var friendly := _make_party([actor, above_threshold, below_threshold])
	var opposition := _make_party([_make_hero("Enemy", 20)])

	var decision := EnemyAI.new(1).choose_action(actor, friendly, opposition)
	_expect_not_null(decision, "eligible injured ally produces a decision")
	if decision != null:
		_expect_equal(decision.ability, support, "target condition allows support ability")
		_expect_equal(decision.target, below_threshold, "target condition filters allies")

	below_threshold.current_hp = 20
	decision = EnemyAI.new(1).choose_action(actor, friendly, opposition)
	_expect_not_null(decision, "basic attack remains available")
	if decision != null:
		_expect_equal(
			decision.ability,
			actor.basic_attack,
			"support skips when no target meets its condition",
		)


func _test_null_cases() -> void:
	var actor := _make_monster("Enemy", 20)
	var friendly := _make_party([actor])
	var defeated := _make_hero("Defeated", 20)
	defeated.current_hp = 0
	var defeated_only := _make_party([defeated])
	_expect_null(
		EnemyAI.new(1).choose_action(actor, friendly, defeated_only),
		"no living opposition returns null",
	)

	actor.current_hp = 0
	_expect_null(
		EnemyAI.new(1).choose_action(actor, friendly, _make_party([_make_hero("Hero", 20)])),
		"defeated actor returns null",
	)
	_expect_null(
		EnemyAI.new(1).choose_action(null, friendly, _make_party([_make_hero("Hero", 20)])),
		"null actor returns null",
	)


func _test_battle_manager_resolves_ai_target() -> void:
	var hero_a := _make_hero("Hero A", 20)
	var hero_b := _make_hero("Hero B", 20)
	hero_b.current_hp = 4
	var monster := _make_monster("Enemy", 20)
	monster.basic_attack.attack = _make_attack(1, 1)
	var manager := BattleManager.new()
	manager.player_party = _make_party([hero_a, hero_b])
	manager.enemy_party = _make_party([monster])
	manager.active_combatant = monster

	var decision := EnemyAI.new(3).choose_action(
		monster,
		manager.enemy_party,
		manager.player_party,
	)
	_expect_not_null(decision, "BattleManager handoff starts with a decision")
	if decision != null:
		var resolved := manager.resolve_targets_for_ability(
			decision.ability,
			monster,
			decision.target,
		)
		_expect_equal(resolved, [hero_b], "BattleManager preserves the AI target")


func _make_party(members: Array) -> BattleParty:
	var party := BattleParty.new()
	for member in members:
		party.add_member(member as Combatant)
	return party


func _make_hero(hero_name: String, hp: int) -> Hero:
	var hero := Hero.new()
	hero.name = hero_name
	hero.max_hp = hp
	hero.current_hp = hp
	hero.max_nrg = 10
	hero.current_nrg = 10
	hero.equipped_weapon = Weapon.new()
	return hero


func _make_monster(monster_name: String, hp: int) -> Monster:
	var monster := Monster.new()
	monster.name = monster_name
	monster.max_hp = hp
	monster.current_hp = hp
	monster.max_nrg = 10
	monster.current_nrg = 10
	monster.basic_attack = Ability.new()
	return monster


func _make_self_ability() -> Ability:
	var ability := Ability.new()
	ability.name = "Self Ability"
	ability.target_type = Ability.TargetType.SELF
	return ability


func _make_ally_ability() -> Ability:
	var ability := Ability.new()
	ability.name = "Ally Ability"
	ability.target_type = Ability.TargetType.ALLY
	return ability


func _make_health_condition(subject: Condition.ConditionsSubject) -> Condition:
	var condition := Condition.new()
	condition.condition_type = Condition.ConditionType.HEALTH_BELOW
	condition.condition_subject = subject
	condition.value = 0.5
	return condition


func _make_attack(min_damage: int, max_damage: int) -> Attack:
	var attack := Attack.new()
	attack.min_damage = min_damage
	attack.max_damage = max_damage
	attack.attack_type = Attack.AttackType.PHYSICAL
	return attack
