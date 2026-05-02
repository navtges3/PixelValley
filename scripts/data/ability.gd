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
	var output = "%s used %s!\n" % [caster.get_colored_name(), self.name]
	if is_ready() and caster.current_nrg >= self.energy_cost:
		if attack != null:
			output += attack.apply_attack(caster, target)
		for utility in utilities:
			output += utility.apply_utility(caster, target)
		self.current_cooldown = self.cooldown + 1
		caster.current_nrg -= self.energy_cost
		return output
	else:
		return ""

func update_cooldown() -> void:
	if self.current_cooldown > 0:
		print(" - Ability %s is on cooldown for %d turns." % [self.name, self.current_cooldown])
		self.current_cooldown -= 1

func _to_string(combatant: Combatant = null) -> String:
	var attack_string = ""
	var utility_string = ""
	if attack != null:
		attack_string = attack._to_string(combatant) + "\n"
	for utility in utilities:
		utility_string += "%s\n" % utility._to_string()
	return "%s%s(Energy cost: %d, Cooldown: %d)" % [attack_string, utility_string, self.energy_cost, self.cooldown]
