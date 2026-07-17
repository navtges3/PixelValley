extends RefCounted
class_name ActiveEffect

enum RemovalReason { NATURAL, CLEANSED, RESTED, BATTLE_ENDED, REPLACED }

var effect: Effect = null
var remaining_turns: int = 0
var lifecycle_revision: int = 0
var source: Combatant = null
var target: Combatant = null
var _applied_stat_deltas: Array[Dictionary] = []
var _is_removed: bool = false

func _init(_effect: Effect, _target: Combatant, _source: Combatant = null) -> void:
	effect = _effect
	target = _target
	source = _source
	remaining_turns = effect.get_duration()

func on_apply() -> String:
	return _apply_changes(Effect.EffectTiming.ON_APPLY)

func apply_tick() -> String:
	return _apply_changes(Effect.EffectTiming.ON_TICK)

func remove(reason: RemovalReason) -> String:
	if _is_removed:
		return ""
	_is_removed = true
	var output := _reverse_applied_modifiers()
	if reason == RemovalReason.NATURAL:
		output += _apply_changes(Effect.EffectTiming.ON_EXPIRE)
	output += _apply_changes(Effect.EffectTiming.ON_REMOVE)
	if reason == RemovalReason.NATURAL:
		output += "%s wore off on %s.\n" % [effect.effect_name, target.get_colored_name()]
	return output

func refresh_duration(new_source: Combatant = null) -> void:
	remaining_turns = effect.get_duration()
	lifecycle_revision += 1
	if new_source != null:
		source = new_source

func get_applied_stat_deltas_data() -> Array[Dictionary]:
	return _applied_stat_deltas.duplicate(true)

func restore_applied_stat_deltas(data: Array) -> void:
	_applied_stat_deltas.clear()
	for delta_data: Dictionary in data:
		var stat: Effect.EffectStat = delta_data.get("stat", Effect.EffectStat.ATTACK)
		var amount: int = int(delta_data.get("amount", 0))
		if Effect.is_modifier_stat(stat) and amount != 0:
			_applied_stat_deltas.append({"stat": stat, "amount": amount})
	_is_removed = false

func restore_legacy_applied_stat_deltas() -> void:
	_applied_stat_deltas.clear()
	for stat_change: EffectStatChange in effect.stat_changes:
		if not stat_change.is_reversible_modifier():
			continue
		var amount := stat_change.get_signed_amount(effect.level)
		if amount != 0:
			_applied_stat_deltas.append({"stat": stat_change.stat, "amount": amount})
	_is_removed = false

func _apply_changes(timing: Effect.EffectTiming) -> String:
	var output := ""
	for stat_change in effect.stat_changes:
		if stat_change.timing != timing:
			continue
		# Modifier cleanup is ledger-driven. Authored expiry/removal modifiers are
		# ignored so stale or mismatched effect data cannot corrupt base stats.
		if stat_change.is_modifier() and timing != Effect.EffectTiming.ON_APPLY:
			continue
		var applied_amount := _apply_stat_change(stat_change.stat, stat_change.get_signed_amount(effect.level))
		if stat_change.is_reversible_modifier() and applied_amount != 0:
			_applied_stat_deltas.append({"stat": stat_change.stat, "amount": applied_amount})
		output += _get_change_output(stat_change.stat, applied_amount)
	return output

func _reverse_applied_modifiers() -> String:
	var output := ""
	_applied_stat_deltas.reverse()
	for delta: Dictionary in _applied_stat_deltas:
		var stat: Effect.EffectStat = delta["stat"]
		var amount: int = -int(delta["amount"])
		var applied_amount := _apply_stat_change(stat, amount)
		output += _get_change_output(stat, applied_amount)
	_applied_stat_deltas.clear()
	return output

func _apply_stat_change(stat: Effect.EffectStat, amount: int) -> int:
	var value_before := _get_stat_value(stat)
	match stat:
		Effect.EffectStat.CURRENT_HP:
			target.current_hp = clampi(target.current_hp + amount, 0, target.max_hp)
		Effect.EffectStat.CURRENT_NRG:
			target.current_nrg = clampi(target.current_nrg + amount, 0, target.max_nrg)
		Effect.EffectStat.MAX_HP:
			target.max_hp = max(target.max_hp + amount, 1)
			target.current_hp = min(target.current_hp, target.max_hp)
		Effect.EffectStat.MAX_NRG:
			target.max_nrg = max(target.max_nrg + amount, 0)
			target.current_nrg = min(target.current_nrg, target.max_nrg)
		Effect.EffectStat.ATTACK:
			target.attack += amount
		Effect.EffectStat.MAGIC:
			target.magic += amount
		Effect.EffectStat.DEFENSE:
			target.defense += amount
		Effect.EffectStat.RESIST:
			target.resist += amount
	return _get_stat_value(stat) - value_before

func _get_stat_value(stat: Effect.EffectStat) -> int:
	match stat:
		Effect.EffectStat.CURRENT_HP:
			return target.current_hp
		Effect.EffectStat.CURRENT_NRG:
			return target.current_nrg
		Effect.EffectStat.MAX_HP:
			return target.max_hp
		Effect.EffectStat.MAX_NRG:
			return target.max_nrg
		Effect.EffectStat.ATTACK:
			return target.attack
		Effect.EffectStat.MAGIC:
			return target.magic
		Effect.EffectStat.DEFENSE:
			return target.defense
		Effect.EffectStat.RESIST:
			return target.resist
	return 0

func _get_change_output(stat: Effect.EffectStat, amount: int) -> String:
	return "%s: %s %s%d.\n" % [target.get_colored_name(), _get_stat_name(stat), "+" if amount >= 0 else "", amount]

func _get_stat_name(stat: Effect.EffectStat) -> String:
	return Effect.EffectStat.keys()[stat].replace("CURRENT_", "").replace("_", " ").capitalize()

func _to_string() -> String:
	return effect._to_string(remaining_turns)
