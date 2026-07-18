extends TestCase


func run_tests() -> int:
	_begin_test_run()
	# Existing ActiveEffect lifecycle tests.
	_test_reversible_modifier_stats()
	_test_refresh_upgrade_and_idempotent_removal()
	_test_natural_expiration_and_cleanup()
	_test_duration_one_receives_one_future_tick()
	_test_duration_three_receives_three_future_ticks()
	_test_refresh_does_not_tick_immediately()
	_test_multiple_effects_expire_safely()
	_test_forced_removal_skips_natural_expiration()
	_test_cleanse_rest_and_battle_cleanup()
	_test_current_values_are_not_reversed()
	_test_mismatched_removal_data_is_ignored()
	_test_save_round_trip_preserves_applied_deltas()
	_test_legacy_save_reconstructs_applied_deltas()

	# EffectManager lookup and validation tests.
	_test_effect_manager_lookup()
	_test_effect_manager_missing_effect()
	_test_effect_manager_get_active_effects_returns_copy()
	_test_shared_effect_id_across_levels_is_valid()
	_test_duplicate_effect_id_and_level_validation()
	_test_empty_effect_id_validation()

	# EffectManager application tests.
	_test_effect_manager_adds_effect()
	_test_effect_manager_refreshes_same_level()
	_test_effect_manager_upgrades_stronger_effect()
	_test_effect_manager_rejects_weaker_effect()
	_test_effect_manager_preserves_source_when_refresh_source_is_null()
	_test_effect_manager_preserves_source_when_upgrade_source_is_null()
	_test_effect_manager_prevents_duplicates()
	_test_effect_manager_application_integration()

	return _finish_test_run("Active effect lifecycle and EffectManager tests")


func _test_reversible_modifier_stats() -> void:
	var modifier_stats: Array[Effect.EffectStat] = [
		Effect.EffectStat.MAX_HP,
		Effect.EffectStat.MAX_NRG,
		Effect.EffectStat.ATTACK,
		Effect.EffectStat.MAGIC,
		Effect.EffectStat.DEFENSE,
		Effect.EffectStat.RESIST,
	]

	for stat: Effect.EffectStat in modifier_stats:
		var combatant := _make_combatant()
		var original_value := _get_stat_value(combatant, stat)

		var buff := _make_effect(
			"buff_%d" % stat,
			stat,
			Effect.EffectOperation.ADD,
			7
		)

		EffectManager.apply_effect(buff, null, combatant)

		_expect_equal(
			_get_stat_value(combatant, stat),
			original_value + 7,
			"positive modifier applies for stat %d" % stat
		)

		EffectManager.remove_effect_by_id(combatant, buff.effect_id)

		_expect_equal(
			_get_stat_value(combatant, stat),
			original_value,
			"positive modifier reverses for stat %d" % stat
		)

		var debuff := _make_effect(
			"debuff_%d" % stat,
			stat,
			Effect.EffectOperation.SUBTRACT,
			30
		)

		EffectManager.apply_effect(debuff, null, combatant)

		var minimum := 1 if stat == Effect.EffectStat.MAX_HP else 0

		if stat in [
			Effect.EffectStat.MAX_HP,
			Effect.EffectStat.MAX_NRG,
		]:
			_expect_equal(
				_get_stat_value(combatant, stat),
				minimum,
				"bounded max modifier records actual delta for stat %d"
				% stat
			)

		EffectManager.remove_effect_by_id(combatant, debuff.effect_id)

		_expect_equal(
			_get_stat_value(combatant, stat),
			original_value,
			"bounded or negative modifier reverses for stat %d" % stat
		)

	var hp_target := _make_combatant()

	var max_hp_debuff := _make_effect(
		"max_hp_clamp",
		Effect.EffectStat.MAX_HP,
		Effect.EffectOperation.SUBTRACT,
		30
	)

	EffectManager.apply_effect(max_hp_debuff, null, hp_target)

	_expect_equal(
		hp_target.current_hp,
		1,
		"current HP clamps when max HP falls"
	)

	EffectManager.remove_effect_by_id(hp_target, max_hp_debuff.effect_id)

	_expect_equal(
		hp_target.max_hp,
		20,
		"max HP restores after clamped application"
	)

	_expect_equal(
		hp_target.current_hp,
		1,
		"reversing max HP does not manufacture healing"
	)


func _test_refresh_upgrade_and_idempotent_removal() -> void:
	var combatant := _make_combatant()

	var level_one := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5,
		1,
		3
	)

	EffectManager.apply_effect(level_one, null, combatant)

	_expect_equal(
		combatant.defense,
		15,
		"initial modifier applies"
	)

	var refreshed := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5,
		1,
		3
	)

	EffectManager.apply_effect(refreshed, null, combatant)

	_expect_equal(
		combatant.defense,
		15,
		"same-level refresh does not stack"
	)

	var upgraded := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5,
		2,
		3
	)

	EffectManager.apply_effect(upgraded, null, combatant)

	_expect_equal(
		combatant.defense,
		18,
		"upgrade replaces the old modifier"
	)

	var active_effect: ActiveEffect = combatant.active_effects[0]

	EffectManager.remove_effect_by_id(combatant, upgraded.effect_id)

	_expect_equal(
		combatant.defense,
		10,
		"cleanse reverses upgraded modifier"
	)

	EffectManager.remove_effect(
		active_effect,
		ActiveEffect.RemovalReason.BATTLE_ENDED
	)

	_expect_equal(
		combatant.defense,
		10,
		"removed effect cannot reverse twice"
	)


func _test_natural_expiration_and_cleanup() -> void:
	var combatant := _make_combatant()

	var effect := _make_effect(
		"short_power",
		Effect.EffectStat.ATTACK,
		Effect.EffectOperation.ADD,
		5
	)

	effect.base_duration = 1

	EffectManager.apply_effect(effect, null, combatant)

	var active_effect: ActiveEffect = combatant.active_effects[0]
	var effects_to_tick := EffectManager.capture_turn_start(combatant)

	EffectManager.process_turn_end(combatant, effects_to_tick)

	_expect_equal(
		combatant.attack,
		10,
		"natural expiration reverses modifier"
	)

	_expect_equal(
		combatant.active_effects.size(),
		0,
		"naturally expired effect leaves active list"
	)

	EffectManager.remove_effect(
		active_effect,
		ActiveEffect.RemovalReason.BATTLE_ENDED
	)

	_expect_equal(
		combatant.attack,
		10,
		"battle cleanup after expiration cannot double-reverse"
	)


func _test_duration_one_receives_one_future_tick() -> void:
	var combatant := _make_combatant()

	var poison := _make_effect(
		"short_poison",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		2
	)

	poison.stat_changes[0].timing = Effect.EffectTiming.ON_TICK
	poison.base_duration = 1

	var application_turn := EffectManager.capture_turn_start(combatant)

	EffectManager.apply_effect(poison, null, combatant)
	EffectManager.process_turn_end(combatant, application_turn)

	_expect_equal(
		combatant.current_hp,
		15,
		"duration-one effect does not tick on its application turn"
	)

	_expect_equal(
		combatant.active_effects[0].remaining_turns,
		1,
		"application turn does not consume duration"
	)

	var first_future_turn := EffectManager.capture_turn_start(combatant)

	EffectManager.process_turn_end(combatant, first_future_turn)

	_expect_equal(
		combatant.current_hp,
		13,
		"duration-one effect receives one future tick"
	)

	_expect_equal(
		combatant.active_effects.size(),
		0,
		"duration-one effect expires after its future tick"
	)


func _test_duration_three_receives_three_future_ticks() -> void:
	var combatant := _make_combatant()

	var poison := _make_effect(
		"long_poison",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		2
	)

	poison.stat_changes[0].timing = Effect.EffectTiming.ON_TICK
	poison.base_duration = 3

	var application_turn := EffectManager.capture_turn_start(combatant)

	EffectManager.apply_effect(poison, null, combatant)
	EffectManager.process_turn_end(combatant, application_turn)

	_expect_equal(
		combatant.current_hp,
		15,
		"duration-three effect skips its application turn"
	)

	for turn_number: int in range(1, 4):
		var turn_snapshot := EffectManager.capture_turn_start(combatant)

		EffectManager.process_turn_end(combatant, turn_snapshot)

		_expect_equal(
			combatant.current_hp,
			15 - (turn_number * 2),
			"duration-three effect applies future tick %d" % turn_number
		)

		if turn_number < 3:
			_expect_equal(
				combatant.active_effects[0].remaining_turns,
				3 - turn_number,
				"duration-three effect tracks remaining future ticks"
			)

	_expect_equal(
		combatant.active_effects.size(),
		0,
		"duration-three effect expires after exactly three future ticks"
	)


func _test_refresh_does_not_tick_immediately() -> void:
	var combatant := _make_combatant()

	var poison := _make_effect(
		"refresh_poison",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		2
	)

	poison.stat_changes[0].timing = Effect.EffectTiming.ON_TICK
	poison.base_duration = 3

	EffectManager.apply_effect(poison, null, combatant)

	var active_effect := combatant.active_effects[0]

	active_effect.remaining_turns = 1

	var refresh_turn := EffectManager.capture_turn_start(combatant)

	EffectManager.apply_effect(poison, null, combatant)
	EffectManager.process_turn_end(combatant, refresh_turn)

	_expect_equal(
		combatant.current_hp,
		15,
		"refreshed effect does not tick on the turn it was refreshed"
	)

	_expect_equal(
		active_effect.remaining_turns,
		3,
		"refresh restores duration without immediately consuming it"
	)

	var next_turn := EffectManager.capture_turn_start(combatant)

	EffectManager.process_turn_end(combatant, next_turn)

	_expect_equal(
		combatant.current_hp,
		13,
		"refreshed effect ticks on the next eligible turn"
	)

	_expect_equal(
		active_effect.remaining_turns,
		2,
		"next eligible tick consumes one refreshed turn"
	)


func _test_multiple_effects_expire_safely() -> void:
	var combatant := _make_combatant()

	var poison := _make_effect(
		"simultaneous_poison",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		2
	)

	poison.stat_changes[0].timing = Effect.EffectTiming.ON_TICK
	poison.base_duration = 1

	var fatigue := _make_effect(
		"simultaneous_fatigue",
		Effect.EffectStat.CURRENT_NRG,
		Effect.EffectOperation.SUBTRACT,
		3
	)

	fatigue.stat_changes[0].timing = Effect.EffectTiming.ON_TICK
	fatigue.base_duration = 1

	EffectManager.apply_effect(poison, null, combatant)
	EffectManager.apply_effect(fatigue, null, combatant)

	var turn_snapshot := EffectManager.capture_turn_start(combatant)

	EffectManager.process_turn_end(combatant, turn_snapshot)

	_expect_equal(
		combatant.current_hp,
		13,
		"first simultaneous effect applies its final tick"
	)

	_expect_equal(
		combatant.current_nrg,
		12,
		"second simultaneous effect applies its final tick"
	)

	_expect_equal(
		combatant.active_effects.size(),
		0,
		"multiple expiring effects are all removed safely"
	)


func _test_forced_removal_skips_natural_expiration() -> void:
	var cleansed_target := _make_combatant()

	cleansed_target.current_hp = 10

	var cleansed_effect := _make_effect(
		"cleansed_expiration_heal",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.ADD,
		4
	)

	cleansed_effect.stat_changes[0].timing = Effect.EffectTiming.ON_EXPIRE
	cleansed_effect.base_duration = 1

	EffectManager.apply_effect(cleansed_effect, null, cleansed_target)
	EffectManager.remove_effect_by_id(
		cleansed_target,
		cleansed_effect.effect_id,
		ActiveEffect.RemovalReason.CLEANSED
	)

	_expect_equal(
		cleansed_target.current_hp,
		10,
		"cleanse does not execute natural-expiration payloads"
	)

	var expired_target := _make_combatant()

	expired_target.current_hp = 10

	var expired_effect := _make_effect(
		"natural_expiration_heal",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.ADD,
		4
	)

	expired_effect.stat_changes[0].timing = Effect.EffectTiming.ON_EXPIRE
	expired_effect.base_duration = 1

	EffectManager.apply_effect(expired_effect, null, expired_target)

	var expiration_turn := EffectManager.capture_turn_start(expired_target)

	EffectManager.process_turn_end(expired_target, expiration_turn)

	_expect_equal(
		expired_target.current_hp,
		14,
		"natural expiration executes its expiration payload"
	)


func _test_cleanse_rest_and_battle_cleanup() -> void:
	var combatant := _make_combatant()

	var combat_effect := _make_effect(
		"combat_magic",
		Effect.EffectStat.MAGIC,
		Effect.EffectOperation.ADD,
		5
	)

	var persistent_effect := _make_effect(
		"persistent_resist",
		Effect.EffectStat.RESIST,
		Effect.EffectOperation.ADD,
		4
	)

	persistent_effect.persistence = Effect.Persistence.PERSISTENT

	EffectManager.apply_effect(combat_effect, null, combatant)
	EffectManager.apply_effect(persistent_effect, null, combatant)

	EffectManager.remove_all_effects(
		combatant,
		ActiveEffect.RemovalReason.BATTLE_ENDED,
		false
	)

	_expect_equal(
		combatant.magic,
		10,
		"battle cleanup reverses combat-only modifier"
	)

	_expect_equal(
		combatant.resist,
		14,
		"battle cleanup preserves persistent modifier"
	)

	_expect_equal(
		combatant.active_effects.size(),
		1,
		"persistent effect remains active after battle"
	)

	combatant.current_hp = 3
	combatant.current_nrg = 2
	combatant.rest()

	_expect_equal(
		combatant.resist,
		10,
		"rest reverses persistent modifier"
	)

	_expect_equal(
		combatant.current_hp,
		combatant.max_hp,
		"rest refills HP after modifier cleanup"
	)

	_expect_equal(
		combatant.current_nrg,
		combatant.max_nrg,
		"rest refills energy after modifier cleanup"
	)

	_expect_equal(
		combatant.active_effects.size(),
		0,
		"rest clears every active effect"
	)


func _test_current_values_are_not_reversed() -> void:
	var combatant := _make_combatant()

	var poison := _make_effect(
		"poison",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		5
	)

	poison.stat_changes[0].timing = Effect.EffectTiming.ON_TICK
	poison.base_duration = 1

	EffectManager.apply_effect(poison, null, combatant)

	var effects_to_tick := EffectManager.capture_turn_start(combatant)

	EffectManager.process_turn_end(combatant, effects_to_tick)

	_expect_equal(
		combatant.current_hp,
		10,
		"current HP tick remains after effect expiration"
	)


func _test_mismatched_removal_data_is_ignored() -> void:
	var combatant := _make_combatant()

	var effect := _make_effect(
		"bad_data",
		Effect.EffectStat.ATTACK,
		Effect.EffectOperation.ADD,
		5
	)

	var mismatched_change := EffectStatChange.new()

	mismatched_change.stat = Effect.EffectStat.ATTACK
	mismatched_change.timing = Effect.EffectTiming.ON_REMOVE
	mismatched_change.operation = Effect.EffectOperation.SUBTRACT
	mismatched_change.base_amount = 99

	effect.stat_changes.append(mismatched_change)

	EffectManager.apply_effect(effect, null, combatant)
	EffectManager.remove_effect_by_id(combatant, effect.effect_id)

	_expect_equal(
		combatant.attack,
		10,
		"authored removal mismatch cannot corrupt modifier stat"
	)


func _test_save_round_trip_preserves_applied_deltas() -> void:
	var original := _make_combatant()

	var effect := _make_effect(
		"saved_defense",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5
	)

	effect.persistence = Effect.Persistence.PERSISTENT

	EffectManager.apply_effect(effect, null, original)

	var saved_effects: Array[Dictionary] = (
		SaveManager._get_active_effects_data(original)
	)

	var loaded := _make_combatant()
	loaded.defense = original.defense

	SaveManager._load_active_effects(saved_effects, loaded)

	_expect_equal(
		loaded.active_effects[0].effect.persistence,
		Effect.Persistence.PERSISTENT,
		"save preserves effect persistence"
	)

	_expect_equal(
		loaded.active_effects[0].effect.effect_id,
		&"saved_defense",
		"save preserves effect identity"
	)

	EffectManager.remove_effect_by_id(loaded, &"saved_defense")

	_expect_equal(
		loaded.defense,
		10,
		"loaded ledger reverses without reapplying modifier"
	)


func _test_legacy_save_reconstructs_applied_deltas() -> void:
	var original := _make_combatant()

	var effect := _make_effect(
		"legacy_attack",
		Effect.EffectStat.ATTACK,
		Effect.EffectOperation.ADD,
		5
	)

	EffectManager.apply_effect(effect, null, original)

	var saved_effects: Array[Dictionary] = (
		SaveManager._get_active_effects_data(original)
	)

	saved_effects[0].erase("applied_stat_deltas")

	var loaded := _make_combatant()
	loaded.attack = original.attack

	SaveManager._load_active_effects(saved_effects, loaded)
	EffectManager.remove_effect_by_id(loaded, &"legacy_attack")

	_expect_equal(
		loaded.attack,
		10,
		"legacy save reconstructs modifier ledger"
	)


func _test_effect_manager_lookup() -> void:
	var combatant := _make_combatant()

	var poison := _make_effect(
		"poison",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		5
	)

	EffectManager.apply_effect(poison, null, combatant)

	var found := EffectManager.find_active_effect(
		combatant,
		&"poison"
	)

	_expect_equal(
		found,
		combatant.active_effects[0],
		"effect manager finds an active effect by stable ID"
	)

	_expect_equal(
		EffectManager.has_effect(combatant, &"poison"),
		true,
		"effect manager reports an existing effect"
	)


func _test_effect_manager_missing_effect() -> void:
	var combatant := _make_combatant()

	_expect_equal(
		EffectManager.find_active_effect(combatant, &"missing"),
		null,
		"effect manager returns null for a missing effect"
	)

	_expect_equal(
		EffectManager.has_effect(combatant, &"missing"),
		false,
		"effect manager reports a missing effect"
	)


func _test_effect_manager_get_active_effects_returns_copy() -> void:
	var combatant := _make_combatant()

	var effect := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5
	)

	EffectManager.apply_effect(effect, null, combatant)

	var returned_effects := EffectManager.get_active_effects(combatant)

	returned_effects.clear()

	_expect_equal(
		combatant.active_effects.size(),
		1,
		"clearing returned effects does not modify the combatant"
	)


func _test_shared_effect_id_across_levels_is_valid() -> void:
	var level_one := _make_effect(
		"poison",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		5,
		1
	)

	var level_two := _make_effect(
		"poison",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		10,
		2
	)

	level_two.effect_name = "Greater Poison"

	var effects: Array[Effect] = [
		level_one,
		level_two,
	]

	var errors := EffectManager.validate_unique_effect_ids(effects)

	_expect_equal(
		errors.size(),
		0,
		"different levels of the same logical effect may share an effect ID"
	)


func _test_duplicate_effect_id_and_level_validation() -> void:
	var first := _make_effect(
		"poison",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		5,
		1
	)

	var copy := _make_effect(
		"poison",
		Effect.EffectStat.CURRENT_HP,
		Effect.EffectOperation.SUBTRACT,
		10,
		1
	)

	copy.effect_name = "Duplicate Poison"

	var effects: Array[Effect] = [
		first,
		copy,
	]

	var errors := EffectManager.validate_unique_effect_ids(effects)

	_expect_equal(
		errors.size(),
		1,
		"duplicate effect IDs at the same level are detected"
	)


func _test_empty_effect_id_validation() -> void:
	var effect := Effect.new()

	effect.effect_name = "Invalid Effect"

	var effects: Array[Effect] = [effect]
	var errors := EffectManager.validate_unique_effect_ids(effects)

	_expect_equal(
		errors.size(),
		1,
		"empty effect IDs are detected"
	)


func _test_effect_manager_adds_effect() -> void:
	var source := _make_combatant()
	source.name = "Caster"

	var target := _make_combatant()
	target.name = "Target"

	var effect := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5
	)

	effect.base_duration = 3

	var result := EffectManager.apply_effect(
		effect,
		source,
		target
	)

	_expect_equal(
		result.status,
		EffectManager.ApplicationStatus.ADDED,
		"new effect returns added status"
	)

	_expect_equal(
		target.active_effects.size(),
		1,
		"new effect creates one active instance"
	)

	_expect_equal(
		result.active_effect,
		target.active_effects[0],
		"result returns the newly created ActiveEffect"
	)

	_expect_equal(
		result.active_effect.effect,
		effect,
		"new active instance stores the applied Effect"
	)

	_expect_equal(
		result.active_effect.source,
		source,
		"new active instance stores its source"
	)

	_expect_equal(
		result.active_effect.target,
		target,
		"new active instance stores its target"
	)

	_expect_equal(
		result.active_effect.remaining_turns,
		3,
		"new active instance receives the effect duration"
	)

	_expect_equal(
		target.defense,
		15,
		"new effect executes ON_APPLY immediately"
	)

	_expect_equal(
		result.output.is_empty(),
		false,
		"new effect produces battle-log output"
	)


func _test_effect_manager_refreshes_same_level() -> void:
	var first_source := _make_combatant()
	first_source.name = "First Caster"

	var second_source := _make_combatant()
	second_source.name = "Second Caster"

	var target := _make_combatant()

	var first_effect := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5,
		1
	)

	first_effect.base_duration = 3

	var first_result := EffectManager.apply_effect(
		first_effect,
		first_source,
		target
	)

	var active_effect := first_result.active_effect

	active_effect.remaining_turns = 1

	var refreshed_effect := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5,
		1
	)

	refreshed_effect.base_duration = 3

	var result := EffectManager.apply_effect(
		refreshed_effect,
		second_source,
		target
	)

	_expect_equal(
		result.status,
		EffectManager.ApplicationStatus.REFRESHED,
		"same-level effect returns refreshed status"
	)

	_expect_equal(
		target.active_effects.size(),
		1,
		"same-level refresh preserves one active instance"
	)

	_expect_equal(
		result.active_effect,
		active_effect,
		"same-level refresh reuses the existing ActiveEffect"
	)

	_expect_equal(
		active_effect.effect,
		first_effect,
		"same-level refresh does not replace the Effect resource"
	)

	_expect_equal(
		target.defense,
		15,
		"same-level refresh does not apply the modifier twice"
	)

	_expect_equal(
		active_effect.remaining_turns,
		3,
		"same-level refresh restores the full duration"
	)

	_expect_equal(
		active_effect.source,
		second_source,
		"same-level refresh replaces source attribution"
	)

	_expect_equal(
		result.previous_level,
		1,
		"same-level refresh reports the previous level"
	)

	_expect_equal(
		result.incoming_level,
		1,
		"same-level refresh reports the incoming level"
	)


func _test_effect_manager_upgrades_stronger_effect() -> void:
	var first_source := _make_combatant()
	first_source.name = "First Caster"

	var second_source := _make_combatant()
	second_source.name = "Second Caster"

	var target := _make_combatant()

	var level_one := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5,
		1,
		3
	)

	level_one.base_duration = 2

	var level_two := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5,
		2,
		3
	)

	level_two.base_duration = 4

	var first_result := EffectManager.apply_effect(
		level_one,
		first_source,
		target
	)

	var original_active_effect := first_result.active_effect

	_expect_equal(
		target.defense,
		15,
		"level-one modifier applies before upgrade"
	)

	var result := EffectManager.apply_effect(
		level_two,
		second_source,
		target
	)

	_expect_equal(
		result.status,
		EffectManager.ApplicationStatus.UPGRADED,
		"stronger effect returns upgraded status"
	)

	_expect_equal(
		target.active_effects.size(),
		1,
		"upgrade preserves one active instance"
	)

	_expect_equal(
		result.active_effect == original_active_effect,
		false,
		"upgrade replaces the old ActiveEffect instance"
	)

	_expect_equal(
		target.active_effects[0],
		result.active_effect,
		"target stores the replacement ActiveEffect"
	)

	_expect_equal(
		original_active_effect in target.active_effects,
		false,
		"old ActiveEffect leaves the target collection"
	)

	_expect_equal(
		result.active_effect.effect,
		level_two,
		"replacement stores the stronger Effect resource"
	)

	_expect_equal(
		result.active_effect.remaining_turns,
		level_two.get_duration(),
		"replacement receives the stronger effect duration"
	)

	_expect_equal(
		result.active_effect.source,
		second_source,
		"replacement receives the new source attribution"
	)

	_expect_equal(
		target.defense,
		18,
		"upgrade reverses the old modifier before applying the new modifier"
	)

	_expect_equal(
		result.previous_level,
		1,
		"upgrade reports the previous level"
	)

	_expect_equal(
		result.incoming_level,
		2,
		"upgrade reports the incoming level"
	)

	EffectManager.remove_effect_by_id(target, level_two.effect_id)

	_expect_equal(
		target.defense,
		10,
		"removing an upgraded effect reverses only the upgraded modifier"
	)


func _test_effect_manager_rejects_weaker_effect() -> void:
	var strong_source := _make_combatant()
	strong_source.name = "Strong Caster"

	var weak_source := _make_combatant()
	weak_source.name = "Weak Caster"

	var target := _make_combatant()

	var level_two := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5,
		2,
		3
	)

	level_two.base_duration = 5

	var level_one := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5,
		1,
		3
	)

	var first_result := EffectManager.apply_effect(
		level_two,
		strong_source,
		target
	)

	var active_effect := first_result.active_effect

	active_effect.remaining_turns = 2

	var result := EffectManager.apply_effect(
		level_one,
		weak_source,
		target
	)

	_expect_equal(
		result.status,
		EffectManager.ApplicationStatus.REJECTED_WEAKER,
		"weaker effect returns rejected status"
	)

	_expect_equal(
		target.active_effects.size(),
		1,
		"weaker effect does not create a duplicate"
	)

	_expect_equal(
		result.active_effect,
		active_effect,
		"weaker rejection returns the existing ActiveEffect"
	)

	_expect_equal(
		active_effect.effect,
		level_two,
		"weaker effect does not replace the stronger Effect"
	)

	_expect_equal(
		target.defense,
		18,
		"weaker effect does not alter the active modifier"
	)

	_expect_equal(
		active_effect.remaining_turns,
		2,
		"weaker effect does not refresh duration"
	)

	_expect_equal(
		active_effect.source,
		strong_source,
		"weaker effect does not replace source attribution"
	)

	_expect_equal(
		result.previous_level,
		2,
		"weaker rejection reports the active level"
	)

	_expect_equal(
		result.incoming_level,
		1,
		"weaker rejection reports the incoming level"
	)


func _test_effect_manager_preserves_source_when_refresh_source_is_null() -> void:
	var original_source := _make_combatant()
	original_source.name = "Original Caster"

	var target := _make_combatant()

	var effect := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5
	)

	EffectManager.apply_effect(
		effect,
		original_source,
		target
	)

	var refreshed_effect := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5
	)

	var result := EffectManager.apply_effect(
		refreshed_effect,
		null,
		target
	)

	_expect_equal(
		result.status,
		EffectManager.ApplicationStatus.REFRESHED,
		"null-source same-level application still refreshes"
	)

	_expect_equal(
		result.active_effect.source,
		original_source,
		"null refresh source preserves existing attribution"
	)


func _test_effect_manager_preserves_source_when_upgrade_source_is_null() -> void:
	var original_source := _make_combatant()
	original_source.name = "Original Caster"

	var target := _make_combatant()

	var level_one := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5,
		1,
		3
	)

	var level_two := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5,
		2,
		3
	)

	EffectManager.apply_effect(
		level_one,
		original_source,
		target
	)

	var result := EffectManager.apply_effect(
		level_two,
		null,
		target
	)

	_expect_equal(
		result.status,
		EffectManager.ApplicationStatus.UPGRADED,
		"null-source stronger application still upgrades"
	)

	_expect_equal(
		result.active_effect.source,
		original_source,
		"null upgrade source preserves existing attribution"
	)


func _test_effect_manager_prevents_duplicates() -> void:
	var target := _make_combatant()

	var first := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5
	)

	var second := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5
	)

	var third := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5,
		2,
		3
	)

	EffectManager.apply_effect(first, null, target)
	EffectManager.apply_effect(second, null, target)
	EffectManager.apply_effect(third, null, target)

	var matching_count := 0

	for active_effect: ActiveEffect in target.active_effects:
		if (
			active_effect.effect != null
			and active_effect.effect.effect_id == &"fortify"
		):
			matching_count += 1

	_expect_equal(
		matching_count,
		1,
		"refreshes and upgrades preserve one instance per effect ID"
	)

	_expect_equal(
		target.active_effects.size(),
		1,
		"repeated application does not append duplicate effects"
	)


func _test_effect_manager_application_integration() -> void:
	var source := _make_combatant()
	var target := _make_combatant()

	var effect := _make_effect(
		"fortify",
		Effect.EffectStat.DEFENSE,
		Effect.EffectOperation.ADD,
		5
	)

	var result := EffectManager.apply_effect(effect, source, target)

	_expect_equal(
		target.active_effects.size(),
		1,
		"EffectManager applies an effect"
	)

	_expect_equal(
		target.active_effects[0].source,
		source,
		"EffectManager preserves the source"
	)

	_expect_equal(
		target.active_effects[0].target,
		target,
		"EffectManager preserves the target"
	)

	_expect_equal(
		target.defense,
		15,
		"EffectManager applies effect mechanics"
	)

	_expect_equal(
		result.output.is_empty(),
		false,
		"EffectManager returns application output"
	)


# Helpers

func _make_combatant() -> Combatant:
	var combatant := Combatant.new()

	combatant.name = "Test Combatant"
	combatant.max_hp = 20
	combatant.current_hp = 15
	combatant.max_nrg = 20
	combatant.current_nrg = 15
	combatant.attack = 10
	combatant.magic = 10
	combatant.defense = 10
	combatant.resist = 10

	return combatant


func _make_effect(
	identity: String,
	stat: Effect.EffectStat,
	operation: Effect.EffectOperation,
	base_amount: int,
	level: int = 1,
	amount_per_level: int = 0
) -> Effect:
	var effect := Effect.new()

	effect.effect_name = identity.capitalize()
	effect.effect_id = StringName(identity)
	effect.level = level

	var change := EffectStatChange.new()

	change.stat = stat
	change.timing = Effect.EffectTiming.ON_APPLY
	change.operation = operation
	change.base_amount = base_amount
	change.amount_per_level = amount_per_level

	effect.stat_changes.append(change)

	return effect


func _get_stat_value(
	combatant: Combatant,
	stat: Effect.EffectStat
) -> int:
	match stat:
		Effect.EffectStat.MAX_HP:
			return combatant.max_hp

		Effect.EffectStat.MAX_NRG:
			return combatant.max_nrg

		Effect.EffectStat.ATTACK:
			return combatant.attack

		Effect.EffectStat.MAGIC:
			return combatant.magic

		Effect.EffectStat.DEFENSE:
			return combatant.defense

		Effect.EffectStat.RESIST:
			return combatant.resist

	return 0
