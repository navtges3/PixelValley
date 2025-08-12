extends Ability
class_name AttackAbility

enum AttackType { PHYSICAL, MAGICAL }

@export var damage: int
@export var attack_type: AttackType

func attack_type_to_string() -> String:
	match attack_type:
		AttackType.PHYSICAL:
			return "Physical"
		AttackType.MAGICAL:
			return "Magical"
	return "Unknown"

func apply_attack(caster: Combatant, target: Combatant) -> void:
	if not use(caster):
		print("%s is still on cooldown." % self.name)
		return

	var damage_dealt = self.damage
	if self.attack_type == AttackType.PHYSICAL:
		var modifier = caster.attack_modifier + caster.stat_block.attack
		damage_dealt += modifier
	elif self.attack_type == AttackType.MAGICAL:
		var modifier = caster.magic_modifier + caster.stat_block.magic
		damage_dealt += modifier
	else:
		print("Unknown attack type for %s." % self.name)
		return
	if damage_dealt < 0:
		damage_dealt = 0
		print("%s was blocked!" % self.name)
	target.take_damage(damage_dealt, self.attack_type)
	return

func get_tooltip() -> String:
	return "Damage: %d\nType: %s\nEnergy Cost: %d\nCooldown: %d" % [self.damage, attack_type_to_string(), self.energy_cost, self.cooldown]