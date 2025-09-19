extends Resource
class_name Ability

@export var name: String
@export var energy_cost: int
@export var cooldown: int
@export var attack: Attack = null
@export var utilities: Array[Utility] = []
var current_cooldown: int

func is_ready() -> bool:
	return current_cooldown <= 0

func use(caster: Combatant, target: Combatant) -> String:
	var output = "%s used %s!\n" % [caster.name, self.name]
	if is_ready() and caster.stat_block.current_nrg >= self.energy_cost:
		if attack != null:
			output += attack.apply_attack(caster, target)
		for utility in utilities:
			output += utility.apply_utility(caster, target)
		self.current_cooldown = self.cooldown + 1
		caster.stat_block.current_nrg -= self.energy_cost
		return output
	else:
		return ""

func update_cooldown() -> void:
	if self.current_cooldown > 0:
		print(" - Ability %s is on cooldown for %d turns." % [self.name, self.current_cooldown])
		self.current_cooldown -= 1

func get_tooltip() -> String:
	return "Energy cost: %d\nCooldown: %d" % [self.energy_cost, self.cooldown]
