extends Ability
class_name AttackAbility

enum AttackType { PHYSICAL, MAGICAL }

@export var min_damage: int
@export var max_damage: int
@export var attack_type: AttackType

func attack_type_to_string() -> String:
	match attack_type:
		AttackType.PHYSICAL:
			return "Physical"
		AttackType.MAGICAL:
			return "Magical"
	return "Unknown"

func apply_attack(caster: Combatant, target: Combatant) -> String:
	if not use(caster):
		print("%s is still on cooldown." % self.name)
		return "%s is still on cooldown." % self.name

	var damage_dealt = randi_range(min_damage, max_damage)
	if self.attack_type == AttackType.PHYSICAL:
		var modifier = caster.attack_modifier + caster.stat_block.attack
		damage_dealt += modifier
	elif self.attack_type == AttackType.MAGICAL:
		var modifier = caster.magic_modifier + caster.stat_block.magic
		damage_dealt += modifier
	else:
		print("Unknown attack type for %s." % self.name)
		return "Unknown attack type."
	var output = "%s used %s for %d damage!\n" % [caster.name, self.name, damage_dealt]
	output += target.take_damage(damage_dealt, self.attack_type)
	return output

func get_tooltip() -> String:
	return "Damage: %d-%d\nType: %s\nEnergy Cost: %d\nCooldown: %d" % [min_damage, max_damage, attack_type_to_string(), self.energy_cost, self.cooldown]
