extends Resource
class_name Ability

enum TargetType {
	SELF,
	ALLY,
	PARTY,
	ENEMY,
	ENEMY_PARTY,
}

@export var name: String
@export var energy_cost: int
@export var cooldown: int
@export var target_type: TargetType = TargetType.ENEMY
@export var attack: Attack = null
@export var caster_effects: Array[Effect] = []
@export var target_effects: Array[Effect] = []
@export var condition: Condition = null

var current_cooldown: int

func is_ready(caster: Combatant = null, target: Combatant = null) -> bool:
	if current_cooldown > 0:
		return false
	if caster != null and not caster.is_alive():
		return false
	if condition != null:
		return condition.check(caster, target)
	return true

func is_ready_for_targets(caster: Combatant = null, targets: Array[Combatant] = []) -> bool:
	if current_cooldown > 0:
		return false
	if caster != null and not caster.is_alive():
		return false
	if condition != null:
		if condition.condition_subject == Condition.ConditionsSubject.TARGET:
			if targets.is_empty():
				return condition.check(caster, null)
			for target: Combatant in targets:
				if condition.check(caster, target):
					return true
			return false
		return condition.check(caster, null)
	return true

func is_single_target() -> bool:
	return target_type in [TargetType.SELF, TargetType.ALLY, TargetType.ENEMY]

func is_multi_target() -> bool:
	return target_type in [TargetType.PARTY, TargetType.ENEMY_PARTY]

func is_friendly() -> bool:
	return target_type in [TargetType.SELF, TargetType.ALLY, TargetType.PARTY]

func is_hostile() -> bool:
	return target_type in [TargetType.ENEMY, TargetType.ENEMY_PARTY]

func requires_manual_target_selection() -> bool:
	return target_type in [TargetType.ALLY, TargetType.ENEMY]

func get_target_type_name() -> String:
	match target_type:
		TargetType.SELF:
			return "Self"
		TargetType.ALLY:
			return "Ally"
		TargetType.PARTY:
			return "Party"
		TargetType.ENEMY:
			return "Enemy"
		TargetType.ENEMY_PARTY:
			return "Enemy Party"
	return "Unknown"

func get_valid_targets(caster: Combatant, friendly_party: BattleParty = null, opposing_party: BattleParty = null) -> Array[Combatant]:
	var result: Array[Combatant] = []
	if caster == null or not caster.is_alive():
		return result
	match target_type:
		TargetType.SELF:
			result.append(caster)
			return result
		TargetType.ALLY, TargetType.PARTY:
			if friendly_party != null:
				return friendly_party.get_alive_members()
			result.append(caster)
			return result
		TargetType.ENEMY, TargetType.ENEMY_PARTY:
			if opposing_party != null:
				return opposing_party.get_alive_members()
			return result
	return result

func is_valid_target(caster: Combatant, target: Combatant, friendly_party: BattleParty = null, opposing_party: BattleParty = null) -> bool:
	if target == null or not target.is_alive():
		return false
	if caster == null or not caster.is_alive():
		return false
	match target_type:
		TargetType.SELF:
			return target == caster
		TargetType.ALLY, TargetType.PARTY:
			if friendly_party != null:
				return friendly_party.has_member(target)
			return target == caster
		TargetType.ENEMY, TargetType.ENEMY_PARTY:
			if opposing_party != null:
				return opposing_party.has_member(target)
			return target != caster
	return false

func use_on_targets(caster: Combatant, targets: Array[Combatant], effect_dispatcher: EffectEventDispatcher = null) -> String:
	if caster == null or not caster.is_alive():
		return ""
	var living_targets: Array[Combatant] = []
	for target: Combatant in targets:
		if target != null and target.is_alive():
			living_targets.append(target)
	if living_targets.is_empty():
		return ""
	if not is_ready_for_targets(caster, living_targets) or caster.current_nrg < self.energy_cost:
		return ""
	var output := "%s used %s!\n" % [caster.get_colored_name(), self.name]
	for target: Combatant in living_targets:
		if attack != null:
			output += attack.apply_attack(caster, target)
		for effect: Effect in target_effects:
			var effect_copy: Effect = effect.duplicate() as Effect
			var result := EffectManager.apply_effect(effect_copy, caster, target, 0, effect_dispatcher)
			output += result.output
	for effect: Effect in caster_effects:
		var effect_copy: Effect = effect.duplicate() as Effect
		var result := EffectManager.apply_effect(
			effect_copy, caster, caster, 0, effect_dispatcher
		)
		output += result.output

	self.current_cooldown = self.cooldown + 1
	caster.current_nrg -= self.energy_cost
	return output

func use(caster: Combatant, target: Combatant = null, effect_dispatcher: EffectEventDispatcher = null) -> String:
	var targets: Array[Combatant] = []
	if target != null:
		targets.append(target)
	elif target_type == TargetType.SELF and caster != null:
		targets.append(caster)
	return use_on_targets(caster, targets, effect_dispatcher)

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
