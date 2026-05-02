extends RefCounted
class_name ActiveEffect

var effect: Effect
var remaining_turns: int
var source
var target

func _init(_effect: Effect, _target, _source = null):
	effect = _effect
	target = _target
	source = _source
	remaining_turns = effect.duration

func on_apply():
	# Apply immediate stat changes for buffs/debuffs
	match effect.type:
		Effect.EffectType.BUFF_ATTACK:
			target.stat_block.attack += effect.strength
		Effect.EffectType.DEBUFF_ATTACK:
			target.stat_block.attack -= effect.strength
		Effect.EffectType.BUFF_MAGIC:
			target.stat_block.magic += effect.strength
		Effect.EffectType.DEBUFF_MAGIC:
			target.stat_block.magic -= effect.strength
		Effect.EffectType.BUFF_DEFENSE:
			target.stat_block.defense += effect.strength
		Effect.EffectType.DEBUFF_DEFENSE:
			target.stat_block.defense -= effect.strength
		Effect.EffectType.BUFF_RESISTANCE:
			target.stat_block.resistance += effect.strength
		Effect.EffectType.DEBUFF_RESISTANCE:
			target.stat_block.resistance -= effect.strength

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
			var dmg_msg = target.take_damage(effect.strength, Attack.AttackType.MAGICAL)
			output = "[color=purple]Poison[/color]: %s" % dmg_msg
	if remaining_turns <= 0:
		output += on_expire()
	return output

func on_expire() -> String:
	var output := ""
	match effect.type:
		Effect.EffectType.BUFF_ATTACK:
			target.stat_block.attack -= effect.strength
			output = "%s's Attack boost wore off.\n" % target.get_colored_name()
		Effect.EffectType.DEBUFF_ATTACK:
			target.stat_block.attack += effect.strength
			output = "%s's Attack penalty wore off.\n" % target.get_colored_name()
		Effect.EffectType.BUFF_MAGIC:
			target.stat_block.magic -= effect.strength
			output = "%s's Magic boost wore off.\n" % target.get_colored_name()
		Effect.EffectType.DEBUFF_MAGIC:
			target.stat_block.magic += effect.strength
			output = "%s's Magic penalty wore off.\n" % target.get_colored_name()
		Effect.EffectType.BUFF_DEFENSE:
			target.stat_block.defense -= effect.strength
			output = "%s's Defense boost wore off.\n" % target.get_colored_name()
		Effect.EffectType.DEBUFF_DEFENSE:
			target.stat_block.defense += effect.strength
			output = "%s's Defense penalty wore off.\n" % target.get_colored_name()
		Effect.EffectType.BUFF_RESISTANCE:
			target.stat_block.resistance -= effect.strength
			output = "%s's Resistance boost wore off.\n" % target.get_colored_name()
		Effect.EffectType.DEBUFF_RESISTANCE:
			target.stat_block.resistance += effect.strength
			output = "%s's Resistance penalty wore off.\n" % target.get_colored_name()
	return output

func _to_string() -> String:
	return effect._to_string(remaining_turns)
