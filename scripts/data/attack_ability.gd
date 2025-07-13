extends Ability
class_name AttackAbility

@export var accuracy: float
@export var damage: int

func apply_attack(target: RefCounted, attack_modifier: int = 0) -> int:
	if not use():
		print("%s is still on cooldown." % self.name)
		return -1

	if randf() > self.accuracy:
		print("%s missed the attack on %s." % [self.name, target.name])
		return 0

	var damage_dealt = self.damage + attack_modifier
	target.take_damage(damage_dealt)
	return damage_dealt