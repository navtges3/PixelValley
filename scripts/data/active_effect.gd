extends RefCounted
class_name ActiveEffect

var effect: Effect
var remaining_turns: int
var source: Combatant = null
var target: Combatant = null

func _init(_effect: Effect, _target: Combatant, _source: Combatant = null) -> void:
	effect = _effect
	target = _target
	source = _source
	remaining_turns = effect.get_duration()

func on_apply() -> String:
	return _apply_changes(Effect.EffectTiming.ON_APPLY)

func on_tick() -> String:
	remaining_turns -= 1
	var output := _apply_changes(Effect.EffectTiming.ON_TICK)
	if remaining_turns <= 0:
		output += on_expire()
	return output

func on_expire() -> String:
	var output := _apply_changes(Effect.EffectTiming.ON_EXPIRE)
	return output + "%s wore off on %s.\n" % [effect.effect_name, target.get_colored_name()]

func refresh_duration() -> void:
	remaining_turns = effect.get_duration()

func upgrade_to(new_effect: Effect, new_source: Combatant) -> String:
	var output := ""
	output += _apply_changes(Effect.EffectTiming.ON_EXPIRE)
	effect = new_effect
	source = new_source
	remaining_turns = effect.get_duration()
	output += on_apply()
	return output

func _apply_changes(timing: Effect.EffectTiming) -> String:
	var output := ""
	for stat_change in effect.stat_changes:
		if stat_change.timing != timing:
			continue
		var amount := stat_change.get_amount(effect.level)
		var signed_amount := amount if stat_change.operation == Effect.EffectOperation.ADD else -amount
		_apply_stat_change(stat_change.stat, signed_amount)
		output += "%s: %s %s%d.\n" % [target.get_colored_name(), _get_stat_name(stat_change.stat), "+" if signed_amount >= 0 else "", signed_amount]
	return output

func _apply_stat_change(stat: Effect.EffectStat, amount: int) -> void:
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

func _get_stat_name(stat: Effect.EffectStat) -> String:
	return Effect.EffectStat.keys()[stat].replace("CURRENT_", "").replace("_", " ").capitalize()

func _to_string() -> String:
	return effect._to_string(remaining_turns)
