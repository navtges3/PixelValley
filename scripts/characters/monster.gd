extends Combatant
class_name Monster

const HEALTH_WEIGHT := 0.5
const ATTACK_WEIGHT := 0.75

@export var gold: int
@export var attack: AttackAbility

func needs_rest() -> bool:
	if self.current_nrg < attack.energy_cost:
		return true
	else:
		return false

func update_cooldown() -> void:
	if self.attack.current_cooldown > 0:
		self.attack.current_cooldown -= 1

func calculate_experience() -> int:
	var health_exp := int(stat_block.max_hp * HEALTH_WEIGHT)
	var damage_avg := float(attack.max_damage + attack.min_damage) / 2
	var attack_exp := int(damage_avg * ATTACK_WEIGHT)
	return (health_exp + attack_exp)
