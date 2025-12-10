extends Resource
class_name ActiveEffect

var effect: Effect
var remaining_turns: int
var source: Combatant
var target: Combatant

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

func on_tick():
	remaining_turns -= 1
	match effect.type:
		Effect.EffectType.HEAL:
			target.heal(effect.strength)
		Effect.EffectType.ENERGY:
			target.recover_energy(effect.strength)
		Effect.EffectType.POISON:
			target.take_damage(effect.strength, Attack.AttackType.MAGICAL)
	if remaining_turns <= 0:
		on_expire()

func on_expire():
	match effect.type:
		Effect.EffectType.BUFF_ATTACK:
			target.stat_block.attack -= effect.strength
		Effect.EffectType.DEBUFF_ATTACK:
			target.stat_block.attack += effect.strength
		Effect.EffectType.BUFF_MAGIC:
			target.stat_block.magic -= effect.strength
		Effect.EffectType.DEBUFF_MAGIC:
			target.stat_block.magic += effect.strength
		Effect.EffectType.BUFF_DEFENSE:
			target.stat_block.defense -= effect.strength
		Effect.EffectType.DEBUFF_DEFENSE:
			target.stat_block.defense += effect.strength
		Effect.EffectType.BUFF_RESISTANCE:
			target.stat_block.resistance -= effect.strength
		Effect.EffectType.DEBUFF_RESISTANCE:
			target.stat_block.resistance += effect.strength

func get_tooltip() -> String:
	var name = effect.type_to_string()
	var turn_text = "turn" if remaining_turns == 1 else "turns"
	return "%s +%d (%d %s)" % [name, effect.strength, remaining_turns, turn_text]
