extends TestCase


var _battle_log: String = ""
var _battle_won_count: int = 0
var _hero_defeated_count: int = 0
var _hero_updated_count: int = 0
var _monster_updated_count: int = 0


func run_tests() -> int:
	_begin_test_run()
	_test_hero_ability_applies_caster_and_target_effects()
	_test_monster_ability_preserves_source()
	_test_potion_uses_hero_as_source()
	_test_dot_and_hot_use_future_turn_ticks()
	_test_rest_removes_all_effects()
	_test_effect_outcomes_are_logged()
	_test_player_turn_effect_death_resolves_defeat_once()
	_test_monster_turn_effect_death_resolves_victory_once()
	_test_victory_cleanup_preserves_persistent_hero_effects()
	_test_defeat_cleanup_preserves_persistent_hero_effects()
	_test_flee_cleanup_preserves_persistent_hero_effects()

	return _finish_test_run("Effect integration tests")


func _test_hero_ability_applies_caster_and_target_effects() -> void:
	var hero := _make_hero()
	var monster := _make_monster()
	var power := _make_effect(
		"hero_power",
		Effect.EffectStat.ATTACK,
		Effect.EffectOperation.ADD,
		3
	)
	var expose := _make_effect(
		"hero_expose",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.SUBTRACT,
		2
	)
	var ability := Ability.new()
	ability.name = "Battle Cry"
	ability.caster_effects.append(power)
	ability.target_effects.append(expose)

	var output := ability.use(hero, monster)
	var self_effect := EffectManager.find_active_effect(hero, power.effect_id)
	var target_effect := EffectManager.find_active_effect(monster, expose.effect_id)

	_expect_not_null(self_effect, "hero self-buff is active")
	_expect_not_null(target_effect, "hero target debuff is active")
	if self_effect != null:
		_expect_equal(self_effect.source, hero, "self-buff source is the hero")
		_expect_equal(self_effect.target, hero, "self-buff target is the hero")
	if target_effect != null:
		_expect_equal(target_effect.source, hero, "target debuff source is the hero")
		_expect_equal(target_effect.target, monster, "target debuff target is the monster")
	_expect_equal(hero.attack, 13, "hero self-buff changes the hero stat")
	_expect_equal(monster.defense, 8, "hero debuff changes the monster stat")
	_expect_contains(output, "applied", "ability application is logged")


func _test_monster_ability_preserves_source() -> void:
	var hero := _make_hero()
	var monster := _make_monster()
	var poison := _make_effect(
		"monster_poison",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		4,
		Effect.EffectTiming.ON_TICK,
		2
	)
	var ability := Ability.new()
	ability.name = "Poison Claw"
	ability.target_effects.append(poison)

	ability.use(monster, hero)
	var active := EffectManager.find_active_effect(hero, poison.effect_id)

	_expect_not_null(active, "monster debuff is active on the hero")
	if active != null:
		_expect_equal(active.source, monster, "monster debuff source is the monster")
		_expect_equal(active.target, hero, "monster debuff target is the hero")


func _test_potion_uses_hero_as_source() -> void:
	var hero := _make_hero()
	hero.inventory.add_potion("attack_potion")

	var output := hero.use_item("attack_potion")
	var active := EffectManager.find_active_effect(hero, &"power")

	_expect_not_null(active, "potion effect is active")
	if active != null:
		_expect_equal(active.source, hero, "potion user is the effect source")
		_expect_equal(active.target, hero, "potion user is the effect target")
	_expect_equal(
		hero.inventory.potions.has("attack_potion"),
		false,
		"potion is consumed"
	)
	_expect_contains(output, "Attack Potion", "potion use is logged")


func _test_dot_and_hot_use_future_turn_ticks() -> void:
	var combatant := _make_hero()
	combatant.current_hp = 10
	var dot := _make_effect(
		"integration_dot",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		3,
		Effect.EffectTiming.ON_TICK,
		2
	)
	var hot := _make_effect(
		"integration_hot",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.ADD,
		2,
		Effect.EffectTiming.ON_TICK,
		2
	)
	var application_turn := EffectManager.capture_turn_start(combatant)

	EffectManager.apply_effect(dot, combatant, combatant)
	EffectManager.apply_effect(hot, combatant, combatant)
	EffectManager.process_turn_end(combatant, application_turn)
	_expect_equal(combatant.current_hp, 10, "new DOT and HOT effects do not tick immediately")

	var first_future_turn := EffectManager.capture_turn_start(combatant)
	EffectManager.process_turn_end(combatant, first_future_turn)
	_expect_equal(combatant.current_hp, 9, "DOT and HOT tick together on the next turn")

	var second_future_turn := EffectManager.capture_turn_start(combatant)
	EffectManager.process_turn_end(combatant, second_future_turn)
	_expect_equal(combatant.current_hp, 8, "DOT and HOT receive their final future tick")
	_expect_equal(combatant.active_effects.is_empty(), true, "expired DOT and HOT are removed")


func _test_rest_removes_all_effects() -> void:
	var hero := _make_hero()
	hero.current_hp = 3
	hero.current_nrg = 2
	var combat_effect := _make_effect(
		"rest_combat_effect",
		Effect.EffectStat.ATTACK,
		Effect.EffectOperation.ADD,
		4
	)
	var persistent_effect := _make_effect(
		"rest_persistent_effect",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5
	)
	persistent_effect.persistence = Effect.Persistence.PERSISTENT

	EffectManager.apply_effect(combat_effect, hero, hero)
	EffectManager.apply_effect(persistent_effect, hero, hero)
	hero.rest()

	_expect_equal(hero.active_effects.is_empty(), true, "rest removes combat and persistent effects")
	_expect_equal(hero.attack, 10, "rest reverses combat-effect modifiers")
	_expect_equal(hero.defense, 10, "rest reverses persistent-effect modifiers")
	_expect_equal(hero.current_hp, hero.max_hp, "rest restores health")
	_expect_equal(hero.current_nrg, hero.max_nrg, "rest restores energy")


func _test_effect_outcomes_are_logged() -> void:
	var source := _make_hero()
	var target := _make_monster()
	var level_one := _make_effect(
		"logged_power",
		Effect.EffectStat.ATTACK,
		Effect.EffectOperation.ADD,
		2
	)
	var level_two: Effect = level_one.duplicate(true) as Effect
	level_two.level = 2
	var weaker: Effect = level_one.duplicate(true) as Effect

	var added := EffectManager.apply_effect(level_one, source, target)
	var refreshed := EffectManager.apply_effect(level_one.duplicate(true) as Effect, source, target)
	var upgraded := EffectManager.apply_effect(level_two, source, target)
	var rejected := EffectManager.apply_effect(weaker, source, target)
	var removed := EffectManager.remove_effect_by_id(
		target,
		level_one.effect_id,
		ActiveEffect.RemovalReason.CLEANSED
	)

	_expect_contains(added.output, "applied", "new application outcome is logged")
	_expect_contains(refreshed.output, "refreshed", "refresh outcome is logged")
	_expect_contains(upgraded.output, "upgraded", "upgrade outcome is logged")
	_expect_contains(rejected.output, "no effect", "weaker rejection is logged")
	_expect_contains(removed, "cleansed", "forced removal reason is logged")


func _test_player_turn_effect_death_resolves_defeat_once() -> void:
	_reset_signal_observations()
	var manager := _make_battle_manager()
	manager.hero.current_hp = 3
	var lethal_dot := _make_effect(
		"hero_lethal_dot",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		5,
		Effect.EffectTiming.ON_TICK,
		1
	)
	EffectManager.apply_effect(lethal_dot, manager.monster, manager.hero)
	manager._hero_effects_at_turn_start = EffectManager.capture_turn_start(manager.hero)
	manager.state = BattleManager.BattleState.PLAYER_TURN

	manager.end_player_turn()
	manager.end_player_turn()

	_expect_equal(manager.state, BattleManager.BattleState.DEFEAT, "hero DOT death resolves defeat")
	_expect_equal(_hero_defeated_count, 1, "defeat signal is emitted exactly once")
	_expect_equal(_battle_won_count, 0, "hero DOT death does not emit victory")
	_expect_true(_hero_updated_count > 0, "hero UI updates after the effect tick")
	_free_battle_manager(manager)


func _test_monster_turn_effect_death_resolves_victory_once() -> void:
	_reset_signal_observations()
	var manager := _make_battle_manager()
	manager.monster.current_hp = 3
	var lethal_dot := _make_effect(
		"monster_lethal_dot",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		5,
		Effect.EffectTiming.ON_TICK,
		1
	)
	EffectManager.apply_effect(lethal_dot, manager.hero, manager.monster)
	manager._monster_effects_at_turn_start = EffectManager.capture_turn_start(manager.monster)
	manager.state = BattleManager.BattleState.MONSTER_TURN

	manager.end_enemy_turn()
	manager.end_enemy_turn()

	_expect_equal(manager.state, BattleManager.BattleState.VICTORY, "monster DOT death resolves victory")
	_expect_equal(_battle_won_count, 1, "victory signal is emitted exactly once")
	_expect_equal(_hero_defeated_count, 0, "monster DOT death does not emit defeat")
	_expect_true(_monster_updated_count > 0, "monster UI updates after the effect tick")
	_free_battle_manager(manager)


func _test_victory_cleanup_preserves_persistent_hero_effects() -> void:
	_reset_signal_observations()
	var manager := _make_battle_manager()
	_apply_cleanup_test_effects(manager)

	manager.end_battle(true)

	_assert_battle_cleanup(manager, "victory")
	_expect_equal(_battle_won_count, 1, "victory cleanup emits victory once")
	_expect_contains(_battle_log, "battle", "victory cleanup is reported in the battle log")
	_free_battle_manager(manager)


func _test_defeat_cleanup_preserves_persistent_hero_effects() -> void:
	_reset_signal_observations()
	var manager := _make_battle_manager()
	_apply_cleanup_test_effects(manager)

	manager.end_battle(false)

	_assert_battle_cleanup(manager, "defeat")
	_expect_equal(_hero_defeated_count, 1, "defeat cleanup emits defeat once")
	_expect_contains(_battle_log, "battle", "defeat cleanup is reported in the battle log")
	_free_battle_manager(manager)


func _test_flee_cleanup_preserves_persistent_hero_effects() -> void:
	_reset_signal_observations()
	var manager := _make_battle_manager()
	_apply_cleanup_test_effects(manager)
	manager.state = BattleManager.BattleState.PLAYER_TURN

	manager.player_fled()

	_assert_battle_cleanup(manager, "flee")
	_expect_equal(manager.state, BattleManager.BattleState.RESOLVING, "flee enters resolving state")
	_expect_contains(_battle_log, "battle", "flee cleanup is reported in the battle log")
	_free_battle_manager(manager)


func _make_battle_manager() -> BattleManager:
	var manager := BattleManager.new()
	manager.hero = _make_hero()
	manager.monster = _make_monster()
	manager.battle_log_updated.connect(_on_battle_log_updated)
	manager.battle_won.connect(_on_battle_won)
	manager.hero_defeated.connect(_on_hero_defeated)
	manager.hero_updated.connect(_on_hero_updated)
	manager.monster_updated.connect(_on_monster_updated)
	add_child(manager)
	return manager


func _make_hero() -> Hero:
	var hero := Hero.new()
	hero.name = "Test Hero"
	hero.max_hp = 20
	hero.current_hp = 20
	hero.max_nrg = 20
	hero.current_nrg = 20
	hero.attack = 10
	hero.magic = 10
	hero.defense = 10
	hero.resist = 10
	hero.inventory = Inventory.new()
	hero.inventory.equipped_weapon = Weapon.new()
	return hero


func _make_monster() -> Monster:
	var monster := Monster.new()
	monster.name = "Test Monster"
	monster.max_hp = 20
	monster.current_hp = 20
	monster.max_nrg = 20
	monster.current_nrg = 20
	monster.attack = 10
	monster.magic = 10
	monster.defense = 10
	monster.resist = 10
	monster.basic_attack = Ability.new()
	return monster


func _make_effect(
	identity: String,
	stat: Effect.EffectStat,
	operation: Effect.EffectOperation,
	base_amount: int,
	timing: Effect.EffectTiming = Effect.EffectTiming.ON_APPLY,
	duration: int = 3
) -> Effect:
	var effect := Effect.new()
	effect.effect_name = identity.replace("_", " ").capitalize()
	effect.effect_id = StringName(identity)
	effect.base_duration = duration

	var change := EffectStatChange.new()
	change.stat = stat
	change.timing = timing
	change.operation = operation
	change.base_amount = base_amount
	effect.stat_changes.append(change)
	return effect


func _apply_cleanup_test_effects(manager: BattleManager) -> void:
	var hero_combat_effect := _make_effect(
		"hero_combat_cleanup",
		Effect.EffectStat.ATTACK,
		Effect.EffectOperation.ADD,
		2
	)
	var hero_persistent_effect := _make_effect(
		"hero_persistent_cleanup",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		3
	)
	hero_persistent_effect.persistence = Effect.Persistence.PERSISTENT
	var monster_effect := _make_effect(
		"monster_cleanup",
		Effect.EffectStat.ATTACK,
		Effect.EffectOperation.ADD,
		4
	)

	EffectManager.apply_effect(hero_combat_effect, manager.hero, manager.hero)
	EffectManager.apply_effect(hero_persistent_effect, manager.hero, manager.hero)
	EffectManager.apply_effect(monster_effect, manager.hero, manager.monster)


func _assert_battle_cleanup(manager: BattleManager, context: String) -> void:
	_expect_equal(
		EffectManager.has_effect(manager.hero, &"hero_combat_cleanup"),
		false,
		"%s removes the hero combat-only effect" % context
	)
	_expect_equal(
		EffectManager.has_effect(manager.hero, &"hero_persistent_cleanup"),
		true,
		"%s preserves the persistent hero effect" % context
	)
	_expect_equal(
		manager.monster.active_effects.is_empty(),
		true,
		"%s removes all monster effects" % context
	)
	_expect_true(_hero_updated_count > 0, "%s refreshes the hero UI" % context)
	_expect_true(_monster_updated_count > 0, "%s refreshes the monster UI" % context)


func _free_battle_manager(manager: BattleManager) -> void:
	remove_child(manager)
	manager.free()


func _reset_signal_observations() -> void:
	_battle_log = ""
	_battle_won_count = 0
	_hero_defeated_count = 0
	_hero_updated_count = 0
	_monster_updated_count = 0


func _on_battle_log_updated(message: String) -> void:
	_battle_log += message


func _on_battle_won(_entries: Array) -> void:
	_battle_won_count += 1


func _on_hero_defeated() -> void:
	_hero_defeated_count += 1


func _on_hero_updated(_hero: Hero) -> void:
	_hero_updated_count += 1


func _on_monster_updated(_monster: Monster) -> void:
	_monster_updated_count += 1
