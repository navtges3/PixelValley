extends Resource
class_name ConditionalAbility

@export var ability: Ability
@export var condition: Condition

func is_ready(caster: Combatant, target: Combatant = null) -> bool:
	if ability == null:
		return false
	return ability.is_ready() and (condition != null and condition.check(caster, target))
