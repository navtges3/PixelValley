extends Resource
class_name Ability

@export var name: String
@export var energy_cost: int
@export var cooldown: int
@export var attack: Attack = null
@export var caster_effects: Array[Effect] = []
@export var target_effects: Array[Effect] = []
@export var condition: Condition = null

var current_cooldown: int

func is_ready(caster: Combatant = null, target: Combatant = null) -> bool:
	if current_cooldown > 0:
		return false
	if condition != null:
		return condition.check(caster, target)
	return true

func use(caster: Combatant, target: Combatant, effect_dispatcher: EffectEventDispatcher = null) -> String:
	var output := "%s used %s!\n" % [caster.get_colored_name(), self.name]
	if is_ready(caster, target) and caster.current_nrg >= self.energy_cost:
		if attack != null:
			output += attack.apply_attack(caster, target)
		for effect: Effect in caster_effects:
			var effect_copy: Effect = effect.duplicate() as Effect
			var result: EffectManager.ApplicationResult = EffectManager.apply_effect(effect_copy, caster, caster, 0, effect_dispatcher)
			output += result.output
		for effect: Effect in target_effects:
			var effect_copy: Effect = effect.duplicate() as Effect
			var result: EffectManager.ApplicationResult = EffectManager.apply_effect(effect_copy, caster, target, 0, effect_dispatcher)
			output += result.output
		self.current_cooldown = self.cooldown + 1
		caster.current_nrg -= self.energy_cost
		return output
	else:
		return ""

func update_cooldown() -> void:
	if self.current_cooldown > 0:
		self.current_cooldown -= 1

func _to_string(combatant: Combatant = null) -> String:
	var attack_string := ""
	var effects_string := ""
	if attack != null:
		attack_string = attack._to_string(combatant) + "\n"
	if not caster_effects.is_empty():
		effects_string += "Self:"
		for effect: Effect in caster_effects:
			effects_string += "\n -%s" % effect._to_string()
		effects_string += "\n"
	if not target_effects.is_empty():
		effects_string += "Target:"
		for effect: Effect in target_effects:
			effects_string += "\n -%s" % effect._to_string()
		effects_string += "\n"
	return "%s%s(Energy cost: %d, Cooldown: %d)" % [attack_string, effects_string, self.energy_cost, self.cooldown]
