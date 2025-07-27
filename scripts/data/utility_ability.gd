extends Ability
class_name UtilityAbility

@export var effect: Effect

func apply_utility(target: RefCounted) -> bool:
	if not use():
		print("%s is still on cooldown." % self.name)
		return false

	target.apply_effect(effect.duplicate())
	return true

func get_tooltip() -> String:
	return "Effect: %s\nEnergy Cost: %d\nCooldown: %d" % [self.effect.get_tooltip(), self.energy_cost, self.cooldown]