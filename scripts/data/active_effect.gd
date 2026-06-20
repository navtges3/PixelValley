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
	remaining_turns = effect.duration

func on_apply() -> void:
	# Apply immediate stat changes for buffs/debuffs
	match effect.type:
		Effect.EffectType.BUFF_ATTACK:
			target.attack += effect.strength
		Effect.EffectType.DEBUFF_ATTACK:
			target.attack -= effect.strength
		Effect.EffectType.BUFF_MAGIC:
			target.magic += effect.strength
		Effect.EffectType.DEBUFF_MAGIC:
			target.magic -= effect.strength
		Effect.EffectType.BUFF_DEFENSE:
			target.defense += effect.strength
		Effect.EffectType.DEBUFF_DEFENSE:
			target.defense -= effect.strength
		Effect.EffectType.BUFF_RESIST:
			target.resist += effect.strength
		Effect.EffectType.DEBUFF_RESIST:
			target.resist -= effect.strength

func on_tick() -> String:
	remaining_turns -= 1
	var output := ""
	match effect.type:
		Effect.EffectType.HEAL:
			target.heal(effect.strength)
			output = "%s regenerates %d HP.\n" % [target.get_colored_name(), effect.strength]
		Effect.EffectType.ENERGY:
			target.recover_energy(effect.strength)
			output = "%s recovers %d energy.\n" % [target.get_colored_name(), effect.strength]
		Effect.EffectType.POISON:
			var dmg_msg := target.take_damage(effect.strength, Attack.AttackType.MAGICAL)
			output = "[color=purple]Poison[/color]: %s" % dmg_msg
	if remaining_turns <= 0:
		output += on_expire()
	return output

func on_expire() -> String:
	var output := ""
	match effect.type:
		Effect.EffectType.BUFF_ATTACK:
			target.attack -= effect.strength
			output = "%s's Attack boost wore off.\n" % target.get_colored_name()
		Effect.EffectType.DEBUFF_ATTACK:
			target.attack += effect.strength
			output = "%s's Attack penalty wore off.\n" % target.get_colored_name()
		Effect.EffectType.BUFF_MAGIC:
			target.magic -= effect.strength
			output = "%s's Magic boost wore off.\n" % target.get_colored_name()
		Effect.EffectType.DEBUFF_MAGIC:
			target.magic += effect.strength
			output = "%s's Magic penalty wore off.\n" % target.get_colored_name()
		Effect.EffectType.BUFF_DEFENSE:
			target.defense -= effect.strength
			output = "%s's Defense boost wore off.\n" % target.get_colored_name()
		Effect.EffectType.DEBUFF_DEFENSE:
			target.defense += effect.strength
			output = "%s's Defense penalty wore off.\n" % target.get_colored_name()
		Effect.EffectType.BUFF_RESIST:
			target.resist -= effect.strength
			output = "%s's Resist boost wore off.\n" % target.get_colored_name()
		Effect.EffectType.DEBUFF_RESIST:
			target.resist += effect.strength
			output = "%s's Resist penalty wore off.\n" % target.get_colored_name()
	return output

func _to_string() -> String:
	return effect._to_string(remaining_turns)
