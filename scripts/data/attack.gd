extends Resource
class_name Attack

enum AttackType { PHYSICAL, MAGICAL }

@export var min_damage: int
@export var max_damage: int
@export var attack_type: AttackType

func apply_attack(caster: Combatant, target: Combatant) -> String:
	var damage_dealt = randi_range(min_damage, max_damage)
	if self.attack_type == AttackType.PHYSICAL:
		damage_dealt += caster.stat_block.attack
	elif self.attack_type == AttackType.MAGICAL:
		damage_dealt += caster.stat_block.magic
	else:
		print("Unknown attack type for %s." % self.name)
		return "Unknown attack type."
	var output = "Attacking for %d damage!\n" % damage_dealt
	output += target.take_damage(damage_dealt, self.attack_type)
	return output

func get_tooltip() -> String:
	var type_to_string = ""
	match attack_type:
		Attack.AttackType.PHYSICAL:
			type_to_string = "Physical"
		Attack.AttackType.MAGICAL:
			type_to_string = "Magical"
	return "%s (%d-%d)" % [type_to_string, min_damage, max_damage]
