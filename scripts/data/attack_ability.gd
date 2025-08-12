extends Ability
class_name AttackAbility

@export var accuracy: float
@export var damage: int

func apply_attack(caster: Combatant, target: Combatant) -> void:
	if not use(caster):
		print("%s is still on cooldown." % self.name)
		return

	if randf() > self.accuracy:
		print("%s missed the attack on %s." % [self.name, target.name])
		return

	var damage_dealt = self.damage + caster.attack - target.defense
	if damage_dealt < 0:
		damage_dealt = 0
		print("%s was blocked!" % self.name)
	target.current_hp -= damage_dealt
	return

func get_tooltip() -> String:
	return "Damage: %d\nAccuracy: %d%%\nEnergy Cost: %d\nCooldown: %d" % [self.damage, int(self.accuracy * 100), self.energy_cost, self.cooldown]