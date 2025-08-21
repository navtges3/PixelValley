extends Ability
class_name UtilityAbility

@export var effects: Array[Effect]

func apply_utility(caster: Combatant) -> String:
	if not use(caster):
		print("%s is still on cooldown." % self.name)
		return "%s is still on cooldown." % self.name


	var output := "%s used %s!" % [caster.name, self.name]
	for effect in effects:
		output += " " + caster.apply_effect(effect.duplicate())
	return output

func get_tooltip() -> String:
	var output := "Energy Cost: %d\nCooldown: %d\n" % [self.energy_cost, self.cooldown]
	for effect in effects:
		output += "Effect: %s\n" %  effect.get_tooltip()
	return output
