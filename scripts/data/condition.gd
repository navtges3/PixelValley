extends Resource
class_name Condition

enum ConditionsSubject { CASTER, TARGET }
enum ConditionType { ALWAYS, HEALTH_BELOW, HEALTH_ABOVE, ENERGY_BELOW, ENERGY_ABOVE }

@export var condition_type: ConditionType = ConditionType.ALWAYS
@export var condition_subject: ConditionsSubject = ConditionsSubject.CASTER
@export var value: float = 0.0

func check(caster: Combatant, target: Combatant = null) -> bool:
	match condition_type:
		ConditionType.ALWAYS:
			return true
		ConditionType.HEALTH_BELOW:
			if target and condition_subject == ConditionsSubject.TARGET:
				return target.stat_block.current_hp < (target.stat_block.max_hp * value)
			return caster.stat_block.current_hp < (caster.stat_block.max_hp * value)
		ConditionType.HEALTH_ABOVE:
			if target and condition_subject == ConditionsSubject.TARGET:
				return target.stat_block.current_hp >= (target.stat_block.max_hp * value)
			return caster.stat_block.current_hp >= (caster.stat_block.max_hp * value)
		ConditionType.ENERGY_BELOW:
			if target and condition_subject == ConditionsSubject.TARGET:
				return target.stat_block.current_nrg < (target.stat_block.max_nrg * value)
			return caster.stat_block.current_nrg < (caster.stat_block.max_nrg * value)
		ConditionType.ENERGY_ABOVE:
			if target and condition_subject == ConditionsSubject.TARGET:
				return target.stat_block.current_nrg >= (target.stat_block.max_nrg * value)
			return caster.stat_block.current_nrg >= (caster.stat_block.max_nrg * value)
	return false
