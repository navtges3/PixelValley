extends Ability
class_name UtilityAbility

@export var effect: Effect

func apply_utility(caster: Combatant) -> String:
	if not use(caster):
		print("%s is still on cooldown." % self.name)
		return "%s is still on cooldown." % self.name

	caster.apply_effect(effect.duplicate())
	return "%s used %s! Applying %d %s for %d turns." % [caster.name, self.name, effect.strength, effect.type_to_string(), effect.duration]

func get_tooltip() -> String:
	return "Effect: %s\nEnergy Cost: %d\nCooldown: %d" % [self.effect.get_tooltip(), self.energy_cost, self.cooldown]