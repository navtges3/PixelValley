extends Ability
class_name AttackAbility

@export var accuracy: float
@export var damage: int

func apply_attack(target: Resource, attack_modifier: int = 0) -> bool:
	if not use():
		print("%s is still on cooldown." % self.name)
		return false

	if randf() > self.accuracy:
		print("%s missed the attack on %s." % [self.name, target.name])
		return false

	target.take_damage(self.damage + attack_modifier)
	return true