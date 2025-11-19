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
				output += caster.apply_effect(effect.duplicate())
			UtilitySubject.TARGET:
				output += target.apply_effect(effect.duplicate())
	return output

func get_tooltip() -> String:
	var output = ""
	var targets = ""
	match subject:
		UtilitySubject.CASTER:
			targets += "Self: "
		UtilitySubject.TARGET:
			targets += "Target: "
	for effect in effects:
		output += "%s%s\n" %  [targets, effect.get_tooltip()]
	return "%s" % [output]
