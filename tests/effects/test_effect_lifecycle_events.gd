extends TestCase


var _events: Array[EffectLifecycleEvent] = []


func run_tests() -> int:
	_begin_test_run()
	_test_application_event_order_and_payloads()
	_test_tick_and_expiration_event_order_and_payloads()
	_test_cleanse_event_payload()
	_test_battle_cleanup_event_order_and_payloads()
	_test_ui_queries_return_snapshots()

	return _finish_test_run("Effect lifecycle event tests")


func _test_application_event_order_and_payloads() -> void:
	var dispatcher := _make_dispatcher()
	var source := _make_combatant("Source")
	var target := _make_combatant("Target")
	var level_one := _make_effect("power", 1, 3)
	var level_two := _make_effect("power", 2, 4)
	var weaker := _make_effect("power", 1, 2)

	EffectManager.apply_effect(level_one, source, target, 0, dispatcher)
	EffectManager.apply_effect(level_one.duplicate(true) as Effect, source, target, 5, dispatcher)
	EffectManager.apply_effect(level_two, source, target, 0, dispatcher)
	EffectManager.apply_effect(weaker, source, target, 0, dispatcher)

	_expect_event_types([
		EffectLifecycleEvent.EventType.ADDED,
		EffectLifecycleEvent.EventType.REFRESHED,
		EffectLifecycleEvent.EventType.UPGRADED,
		EffectLifecycleEvent.EventType.REJECTED_WEAKER,
	], "application transitions emit once and in order")
	_assert_event(_events[0], target, &"power", 1, 0, 1, 3, ActiveEffect.RemovalReason.NATURAL, "add")
	_assert_event(_events[1], target, &"power", 1, 1, 1, 5, ActiveEffect.RemovalReason.NATURAL, "refresh")
	_assert_event(_events[2], target, &"power", 2, 1, 2, 4, ActiveEffect.RemovalReason.NATURAL, "upgrade")
	_assert_event(_events[3], target, &"power", 2, 2, 1, 4, ActiveEffect.RemovalReason.NATURAL, "weaker rejection")


func _test_tick_and_expiration_event_order_and_payloads() -> void:
	var dispatcher := _make_dispatcher()
	var target := _make_combatant("Target")
	var poison := _make_effect("poison", 1, 2, Effect.EffectTiming.ON_TICK)
	var application_turn := EffectManager.capture_turn_start(target)

	EffectManager.apply_effect(poison, target, target, 0, dispatcher)
	EffectManager.process_turn_end(target, application_turn, dispatcher)
	_expect_event_types(
		[EffectLifecycleEvent.EventType.ADDED],
		"application turn does not emit a tick"
	)

	var first_future_turn := EffectManager.capture_turn_start(target)
	EffectManager.process_turn_end(target, first_future_turn, dispatcher)
	var second_future_turn := EffectManager.capture_turn_start(target)
	EffectManager.process_turn_end(target, second_future_turn, dispatcher)

	_expect_event_types([
		EffectLifecycleEvent.EventType.ADDED,
		EffectLifecycleEvent.EventType.TICKED,
		EffectLifecycleEvent.EventType.TICKED,
		EffectLifecycleEvent.EventType.REMOVED,
	], "ticks precede the single expiration event")
	_assert_event(_events[1], target, &"poison", 1, 0, 0, 1, ActiveEffect.RemovalReason.NATURAL, "first future tick")
	_assert_event(_events[2], target, &"poison", 1, 0, 0, 0, ActiveEffect.RemovalReason.NATURAL, "final future tick")
	_assert_event(_events[3], target, &"poison", 1, 1, 0, 0, ActiveEffect.RemovalReason.NATURAL, "natural expiration")


func _test_cleanse_event_payload() -> void:
	var dispatcher := _make_dispatcher()
	var target := _make_combatant("Target")
	var effect := _make_effect("fortify", 2, 3)

	EffectManager.apply_effect(effect, target, target, 0, dispatcher)
	EffectManager.remove_effect_by_id(
		target,
		effect.effect_id,
		ActiveEffect.RemovalReason.CLEANSED,
		dispatcher
	)

	_expect_event_types([
		EffectLifecycleEvent.EventType.ADDED,
		EffectLifecycleEvent.EventType.REMOVED,
	], "cleanse emits one removal after add")
	_assert_event(_events[1], target, &"fortify", 2, 2, 0, 3, ActiveEffect.RemovalReason.CLEANSED, "cleanse")


func _test_battle_cleanup_event_order_and_payloads() -> void:
	_events.clear()
	var manager := BattleManager.new()
	manager.hero = _make_hero()
	manager.monster = _make_monster()
	manager.effect_lifecycle_changed.connect(_record_event)
	var hero_combat := _make_effect("hero_combat", 1, 3)
	var hero_persistent := _make_effect("hero_persistent", 1, 3)
	hero_persistent.persistence = Effect.Persistence.PERSISTENT
	var monster_effect := _make_effect("monster_combat", 1, 3)
	EffectManager.apply_effect(hero_combat, manager.hero, manager.hero)
	EffectManager.apply_effect(hero_persistent, manager.hero, manager.hero)
	EffectManager.apply_effect(monster_effect, manager.hero, manager.monster)

	manager.end_battle(false)

	_expect_event_types([
		EffectLifecycleEvent.EventType.REMOVED,
		EffectLifecycleEvent.EventType.REMOVED,
	], "battle cleanup emits one event per removed combat effect")
	_assert_event(_events[0], manager.hero, &"hero_combat", 1, 1, 0, 3, ActiveEffect.RemovalReason.BATTLE_ENDED, "hero battle cleanup")
	_assert_event(_events[1], manager.monster, &"monster_combat", 1, 1, 0, 3, ActiveEffect.RemovalReason.BATTLE_ENDED, "monster battle cleanup")
	_expect_equal(EffectManager.has_effect(manager.hero, &"hero_persistent"), true, "battle cleanup preserves persistent hero effects")


func _test_ui_queries_return_snapshots() -> void:
	var target := _make_combatant("Target")
	var effect := _make_effect("ward", 2, 4)
	EffectManager.apply_effect(effect, target, target)

	var views := EffectManager.get_active_effects(target)
	_expect_equal(views.size(), 1, "active-effect query returns one view")
	_expect_equal(views[0].effect_id, &"ward", "effect view exposes the stable ID")
	_expect_equal(views[0].level, 2, "effect view exposes the level")
	_expect_equal(views[0].remaining_turns, 4, "effect view exposes future turns")
	_expect_equal(EffectManager.get_effect_remaining_turns(target, &"ward"), 4, "remaining-turn query follows future-turn rules")
	_expect_equal(EffectManager.has_effect(target, &"ward"), true, "has-effect query finds the effect")

	views.clear()
	_expect_equal(target.active_effects.size(), 1, "mutating the returned collection cannot mutate runtime state")


func _make_dispatcher() -> EffectEventDispatcher:
	_events.clear()
	var dispatcher := EffectEventDispatcher.new()
	dispatcher.lifecycle_event.connect(_record_event)
	return dispatcher


func _record_event(event: EffectLifecycleEvent) -> void:
	_events.append(event)


func _make_combatant(combatant_name: String) -> Combatant:
	var combatant := Combatant.new()
	combatant.name = combatant_name
	combatant.max_hp = 20
	combatant.current_hp = 20
	combatant.max_nrg = 10
	combatant.current_nrg = 10
	combatant.attack = 10
	combatant.magic = 10
	combatant.defense = 10
	combatant.resist = 10
	return combatant


func _make_hero() -> Hero:
	var hero := Hero.new()
	hero.name = "Hero"
	hero.max_hp = 20
	hero.current_hp = 20
	hero.max_nrg = 10
	hero.current_nrg = 10
	hero.attack = 10
	hero.magic = 10
	hero.defense = 10
	hero.resist = 10
	hero.inventory = Inventory.new()
	hero.inventory.equipped_weapon = Weapon.new()
	return hero


func _make_monster() -> Monster:
	var monster := Monster.new()
	monster.name = "Monster"
	monster.max_hp = 20
	monster.current_hp = 20
	monster.max_nrg = 10
	monster.current_nrg = 10
	monster.attack = 10
	monster.magic = 10
	monster.defense = 10
	monster.resist = 10
	monster.basic_attack = Ability.new()
	return monster


func _make_effect(
	identity: String,
	level: int,
	duration: int,
	timing: Effect.EffectTiming = Effect.EffectTiming.ON_APPLY
) -> Effect:
	var effect := Effect.new()
	effect.effect_name = identity.replace("_", " ").capitalize()
	effect.effect_id = StringName(identity)
	effect.level = level
	effect.base_duration = duration
	var change := EffectStatChange.new()
	change.stat = Effect.EffectStat.ATTACK
	change.operation = Effect.EffectOperation.ADD
	change.base_amount = 1
	change.timing = timing
	effect.stat_changes.append(change)
	return effect


func _assert_event(
	event: EffectLifecycleEvent,
	target: Combatant,
	effect_id: StringName,
	level: int,
	previous_level: int,
	incoming_level: int,
	remaining_turns: int,
	removal_reason: ActiveEffect.RemovalReason,
	context: String
) -> void:
	_expect_equal(event.target, target, "%s payload target" % context)
	_expect_equal(event.effect_id, effect_id, "%s payload effect ID" % context)
	_expect_equal(event.level, level, "%s payload level" % context)
	_expect_equal(event.previous_level, previous_level, "%s payload previous level" % context)
	_expect_equal(event.incoming_level, incoming_level, "%s payload incoming level" % context)
	_expect_equal(event.remaining_turns, remaining_turns, "%s payload remaining turns" % context)
	_expect_equal(event.removal_reason, removal_reason, "%s payload removal reason" % context)


func _expect_event_types(expected: Array[EffectLifecycleEvent.EventType], message: String) -> void:
	var actual: Array[EffectLifecycleEvent.EventType] = []
	for event: EffectLifecycleEvent in _events:
		actual.append(event.type)
	_expect_equal(actual, expected, message)
