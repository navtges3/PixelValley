extends Node

var _failures: int = 0

func _ready() -> void:
	_test_reversible_modifier_stats()
	_test_refresh_upgrade_and_idempotent_removal()
	_test_natural_expiration_and_cleanup()
	_test_cleanse_rest_and_battle_cleanup()
	_test_current_values_are_not_reversed()
	_test_mismatched_removal_data_is_ignored()
	_test_save_round_trip_preserves_applied_deltas()
	_test_legacy_save_reconstructs_applied_deltas()
	
	_test_effect_manager_lookup()
	_test_effect_manager_missing_effect()
	_test_effect_manager_get_active_effects_returns_copy()
	_test_duplicate_effect_id_validation()
	_test_empty_effect_id_validation()

	if _failures == 0:
		print("Active effect lifecycle tests passed.")
		get_tree().quit(0)
	else:
		printerr("Active effect lifecycle tests failed: %d" % _failures)
		get_tree().quit(1)

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
		var buff := _make_effect("buff_%d" % stat, stat, Effect.EffectOperation.ADD, 7)
		combatant.apply_effect(buff)
		_expect_equal(_get_stat_value(combatant, stat), original_value + 7, "positive modifier applies for stat %d" % stat)
		combatant.remove_effect(buff.effect_id)
		_expect_equal(_get_stat_value(combatant, stat), original_value, "positive modifier reverses for stat %d" % stat)

		var debuff := _make_effect("debuff_%d" % stat, stat, Effect.EffectOperation.SUBTRACT, 30)
		combatant.apply_effect(debuff)
		var minimum := 1 if stat == Effect.EffectStat.MAX_HP else 0
		if stat in [Effect.EffectStat.MAX_HP, Effect.EffectStat.MAX_NRG]:
			_expect_equal(_get_stat_value(combatant, stat), minimum, "bounded max modifier records actual delta for stat %d" % stat)
		combatant.remove_effect(debuff.effect_id)
		_expect_equal(_get_stat_value(combatant, stat), original_value, "bounded or negative modifier reverses for stat %d" % stat)

	var hp_target := _make_combatant()
	var max_hp_debuff := _make_effect("max_hp_clamp", Effect.EffectStat.MAX_HP, Effect.EffectOperation.SUBTRACT, 30)
	hp_target.apply_effect(max_hp_debuff)
	_expect_equal(hp_target.current_hp, 1, "current HP clamps when max HP falls")
	hp_target.remove_effect(max_hp_debuff.effect_id)
	_expect_equal(hp_target.max_hp, 20, "max HP restores after clamped application")
	_expect_equal(hp_target.current_hp, 1, "reversing max HP does not manufacture healing")

func _test_refresh_upgrade_and_idempotent_removal() -> void:
	var combatant := _make_combatant()
	var level_one := _make_effect("fortify", Effect.EffectStat.DEFENSE, Effect.EffectOperation.ADD, 5, 1, 3)
	combatant.apply_effect(level_one)
	_expect_equal(combatant.defense, 15, "initial modifier applies")

	var refreshed := _make_effect("fortify", Effect.EffectStat.DEFENSE, Effect.EffectOperation.ADD, 5, 1, 3)
	combatant.apply_effect(refreshed)
	_expect_equal(combatant.defense, 15, "same-level refresh does not stack")

	var upgraded := _make_effect("fortify", Effect.EffectStat.DEFENSE, Effect.EffectOperation.ADD, 5, 2, 3)
	combatant.apply_effect(upgraded)
	_expect_equal(combatant.defense, 18, "upgrade replaces the old modifier")

	var active_effect: ActiveEffect = combatant.active_effects[0]
	combatant.remove_effect(upgraded.effect_id)
	_expect_equal(combatant.defense, 10, "cleanse reverses upgraded modifier")
	active_effect.remove(ActiveEffect.RemovalReason.BATTLE_ENDED)
	_expect_equal(combatant.defense, 10, "removed effect cannot reverse twice")

func _test_natural_expiration_and_cleanup() -> void:
	var combatant := _make_combatant()
	var effect := _make_effect("short_power", Effect.EffectStat.ATTACK, Effect.EffectOperation.ADD, 5)
	effect.base_duration = 1
	combatant.apply_effect(effect)
	var active_effect: ActiveEffect = combatant.active_effects[0]
	var effects_to_tick: Array[ActiveEffect] = combatant.active_effects.duplicate()
	combatant.process_active_effects(effects_to_tick)
	_expect_equal(combatant.attack, 10, "natural expiration reverses modifier")
	_expect_equal(combatant.active_effects.size(), 0, "naturally expired effect leaves active list")
	active_effect.remove(ActiveEffect.RemovalReason.BATTLE_ENDED)
	_expect_equal(combatant.attack, 10, "battle cleanup after expiration cannot double-reverse")

func _test_cleanse_rest_and_battle_cleanup() -> void:
	var combatant := _make_combatant()
	var combat_effect := _make_effect("combat_magic", Effect.EffectStat.MAGIC, Effect.EffectOperation.ADD, 5)
	var persistent_effect := _make_effect("persistent_resist", Effect.EffectStat.RESIST, Effect.EffectOperation.ADD, 4)
	persistent_effect.persistence = Effect.Persistence.PERSISTENT
	combatant.apply_effect(combat_effect)
	combatant.apply_effect(persistent_effect)
	combatant.clear_active_effects(ActiveEffect.RemovalReason.BATTLE_ENDED, false)
	_expect_equal(combatant.magic, 10, "battle cleanup reverses combat-only modifier")
	_expect_equal(combatant.resist, 14, "battle cleanup preserves persistent modifier")
	_expect_equal(combatant.active_effects.size(), 1, "persistent effect remains active after battle")

	combatant.current_hp = 3
	combatant.current_nrg = 2
	combatant.rest()
	_expect_equal(combatant.resist, 10, "rest reverses persistent modifier")
	_expect_equal(combatant.current_hp, combatant.max_hp, "rest refills HP after modifier cleanup")
	_expect_equal(combatant.current_nrg, combatant.max_nrg, "rest refills energy after modifier cleanup")
	_expect_equal(combatant.active_effects.size(), 0, "rest clears every active effect")

func _test_current_values_are_not_reversed() -> void:
	var combatant := _make_combatant()
	var poison := _make_effect("poison", Effect.EffectStat.CURRENT_HP, Effect.EffectOperation.SUBTRACT, 5)
	poison.stat_changes[0].timing = Effect.EffectTiming.ON_TICK
	poison.base_duration = 1
	combatant.apply_effect(poison)
	var effects_to_tick: Array[ActiveEffect] = combatant.active_effects.duplicate()
	combatant.process_active_effects(effects_to_tick)
	_expect_equal(combatant.current_hp, 10, "current HP tick remains after effect expiration")

func _test_mismatched_removal_data_is_ignored() -> void:
	var combatant := _make_combatant()
	var effect := _make_effect("bad_data", Effect.EffectStat.ATTACK, Effect.EffectOperation.ADD, 5)
	var mismatched_change := EffectStatChange.new()
	mismatched_change.stat = Effect.EffectStat.ATTACK
	mismatched_change.timing = Effect.EffectTiming.ON_REMOVE
	mismatched_change.operation = Effect.EffectOperation.SUBTRACT
	mismatched_change.base_amount = 99
	effect.stat_changes.append(mismatched_change)
	combatant.apply_effect(effect)
	combatant.remove_effect(effect.effect_id)
	_expect_equal(combatant.attack, 10, "authored removal mismatch cannot corrupt modifier stat")

func _test_save_round_trip_preserves_applied_deltas() -> void:
	var original := _make_combatant()
	var effect := _make_effect("saved_defense", Effect.EffectStat.DEFENSE, Effect.EffectOperation.ADD, 5)
	effect.persistence = Effect.Persistence.PERSISTENT
	original.apply_effect(effect)
	var saved_effects: Array[Dictionary] = SaveManager._get_active_effects_data(original)

	var loaded := _make_combatant()
	loaded.defense = original.defense
	SaveManager._load_active_effects(saved_effects, loaded)
	_expect_equal(loaded.active_effects[0].effect.persistence, Effect.Persistence.PERSISTENT, "save preserves effect persistence")
	_expect_equal(loaded.active_effects[0].effect.effect_id, &"saved_defense", "save preserves effect identity")
	loaded.remove_effect(&"saved_defense")
	_expect_equal(loaded.defense, 10, "loaded ledger reverses without reapplying modifier")

func _test_legacy_save_reconstructs_applied_deltas() -> void:
	var original := _make_combatant()
	var effect := _make_effect("legacy_attack", Effect.EffectStat.ATTACK, Effect.EffectOperation.ADD, 5)
	original.apply_effect(effect)
	var saved_effects: Array[Dictionary] = SaveManager._get_active_effects_data(original)
	saved_effects[0].erase("applied_stat_deltas")

	var loaded := _make_combatant()
	loaded.attack = original.attack
	SaveManager._load_active_effects(saved_effects, loaded)
	loaded.remove_effect(&"legacy_attack")
	_expect_equal(loaded.attack, 10, "legacy save reconstructs modifier ledger")

func _test_effect_manager_lookup() -> void:
	var combatant := _make_combatant()
	var poison := _make_effect("poison", Effect.EffectStat.CURRENT_HP, Effect.EffectOperation.SUBTRACT, 5)
	combatant.active_effects.append(ActiveEffect.new(poison, combatant))
	var found := EffectManager.find_active_effect(combatant, &"poison")
	_expect_equal(found, combatant.active_effects[0], "effect manager finds an active effect by stable ID")
	_expect_equal(EffectManager.has_effect(combatant, &"poison"), true, "effect manager reports an existing effect")

func _test_effect_manager_missing_effect() -> void:
	var combatant := _make_combatant()
	_expect_equal(EffectManager.find_active_effect(combatant, &"missing"), null, "effect manager returns null for a missing effect")
	_expect_equal(EffectManager.has_effect(combatant, &"missing"), false, "effect manager reports a missing effect")

func _test_effect_manager_get_active_effects_returns_copy() -> void:
	var combatant := _make_combatant()
	var effect := _make_effect("fortify", Effect.EffectStat.DEFENSE, Effect.EffectOperation.ADD, 5)
	combatant.active_effects.append(ActiveEffect.new(effect, combatant))
	var returned_effects := EffectManager.get_active_effects(combatant)
	returned_effects.clear()
	_expect_equal(combatant.active_effects.size(), 1, "clearing returned effects does not modify the combatant")

func _test_duplicate_effect_id_validation() -> void:
	var first := _make_effect("poison", Effect.EffectStat.CURRENT_HP, Effect.EffectOperation.SUBTRACT, 5)
	var dupe := _make_effect("poison", Effect.EffectStat.CURRENT_HP, Effect.EffectOperation.SUBTRACT, 10)
	dupe.effect_name = "Greater Poison"
	var effects: Array[Effect] = [first, dupe]
	var errors := EffectManager.validate_unique_effect_ids(effects)
	_expect_equal(errors.size(), 1, "duplicate effect IDs are detected")

func _test_empty_effect_id_validation() -> void:
	var effect := Effect.new()
	effect.effect_name = "Invalid Effect"
	var effects: Array[Effect] = [effect]
	var errors := EffectManager.validate_unique_effect_ids(effects)
	_expect_equal(errors.size(), 1, "empty effect IDs are detected")

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

func _make_effect(identity: String, stat: Effect.EffectStat, operation: Effect.EffectOperation,
	base_amount: int, level: int = 1, amount_per_level: int = 0) -> Effect:
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

func _get_stat_value(combatant: Combatant, stat: Effect.EffectStat) -> int:
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

func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failures += 1
	printerr("FAIL: %s (expected %s, got %s)" % [message, expected, actual])
