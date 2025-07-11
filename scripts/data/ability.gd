extends Resource

class_name Ability

@export var name: String
@export var energy_cost: int
@export var cooldown: int
var current_cooldown: int

func is_ready() -> bool:
	return current_cooldown <= 0

func use() -> bool:
	if is_ready():
		self.current_cooldown = self.cooldown
		return true
	else:
		return false

func update_cooldown() -> void:
	if self.current_cooldown > 0:
		print(" - Ability %s is on cooldown for %d turns." % [self.name, self.current_cooldown])
		self.current_cooldown -= 1
