extends Combatant
class_name Monster

const HEALTH_WEIGHT := 0.5
const ATTACK_WEIGHT := 0.75

@export var attack: int
@export var gold: int

func calculate_experience() -> int:
	var health_exp := int(stat_block.max_hp * HEALTH_WEIGHT)
	var attack_exp := int(attack * ATTACK_WEIGHT)
	return (health_exp + attack_exp)
