extends Combatant
class_name Monster

const HEALTH_WEIGHT := 0.5
const ATTACK_WEIGHT := 0.75

@export var gold: int
@export var basic_attack: AttackAbility
@export var conditional_abilities: Array[ConditionalAbility]

func choose_ability(target: Combatant) -> Ability:
	for conditional in conditional_abilities:
		if conditional.is_ready(self, target) and stat_block.current_nrg >= conditional.ability.energy_cost:
			return conditional.ability
	return basic_attack

func update_cooldown() -> void:
	if self.basic_attack.current_cooldown > 0:
		self.basic_attack.current_cooldown -= 1
	for conditional in conditional_abilities:
		if conditional.ability.current_cooldown > 0:
			conditional.ability.current_cooldown -= 1

func calculate_experience() -> int:
	var health_exp := int(stat_block.max_hp * HEALTH_WEIGHT)
	var damage_avg := float(basic_attack.max_damage + basic_attack.min_damage) / 2
	var attack_exp := int(damage_avg * ATTACK_WEIGHT)
	return (health_exp + attack_exp)
