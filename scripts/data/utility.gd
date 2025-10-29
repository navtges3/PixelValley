extends Resource
class_name Utility

enum UtilitySubject { CASTER, TARGET }

@export var effects: Array[Effect]
@export var subject: UtilitySubject

func apply_utility(caster: Combatant, target: Combatant) -> String:
	var output := ""
	for effect in effects:
		match subject:
			UtilitySubject.CASTER:
				output += caster.apply_effect(effect.duplicate()) + "\n"
			UtilitySubject.TARGET:
				output += target.apply_effect(effect.duplicate()) + "\n"
	return output

func get_tooltip() -> String:
	var output := "Energy Cost: %d\nCooldown: %d\n" % [self.energy_cost, self.cooldown]
	match subject:
		UtilitySubject.CASTER:
			output += "Affects: Caster\n"
		UtilitySubject.TARGET:
			output += "Affects: Target\n"
	for effect in effects:
		output += "Effect: %s\n" %  effect.get_tooltip()
	return output
