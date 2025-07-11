extends Ability
class_name UtilityAbility

@export var utility_effect: String
@export var strength: int
@export var duration: int

func apply_utility(target: HeroInstance) -> bool:
	if not use():
		print("%s is still on cooldown." % self.name)
		return false

	target.apply_effect(utility_effect, strength, duration)
	return true