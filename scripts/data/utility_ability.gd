extends Ability
class_name UtilityAbility

@export var effects: Array[Effect]

func apply_utility(caster: Combatant) -> String:
	if not use(caster):
		print("%s is still on cooldown." % self.name)
		return "%s is still on cooldown." % self.name

	
	var output := "%s used %s!"
	for effect in effects:
		caster.apply_effect(effect.duplicate())
		output += " Applying %d %s for %d turns." % [effect.strength, effect.type_to_string(), effect.duration]
	return output

func get_tooltip() -> String:
	var output := "Energy Cost: %d\nCooldown: %d\n" % [self.energy_cost, self.cooldown]
	for effect in effects:
		output += "Effect: %s\n" %  effect.get_tooltip()
	return output
