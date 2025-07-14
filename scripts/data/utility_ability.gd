extends Ability
class_name UtilityAbility

@export var utility_effect: String
@export var strength: int
@export var duration: int

func apply_utility(target: RefCounted) -> bool:
	if not use():
		print("%s is still on cooldown." % self.name)
		return false

	target.apply_effect(utility_effect, strength, duration)
	return true

func get_tooltip() -> String:
	return "Effect: %s\nStrength: %d\nDuration: %d\nEnergy Cost: %d\nCooldown: %d" % [self.utility_effect, self.strength, self.duration, self.energy_cost, self.cooldown]