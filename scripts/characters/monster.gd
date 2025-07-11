extends Resource

class_name Monster

@export var name: String
@export var base_hp: int
@export var base_attack: int
var level := 1
var max_hp: int
var current_hp: int

func set_level(new_level: int) -> void:
	if new_level < 1:
		new_level = 1
	self.level = new_level
	self.max_hp = level * base_hp
	self.current_hp = self.max_hp

func take_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)

func get_attack_damage() -> int:
	return int(base_attack * level)

func get_hp_percentage() -> float:
	if max_hp == 0:
		return 0.0
	return float(current_hp) / float(max_hp)

func is_alive() -> bool:
	return current_hp > 0

func calculate_experience() -> int:
	var health_weight := 0.5
	var attack_weight := 0.75
	var health_exp := int(current_hp * health_weight)
	var attack_exp := int(get_attack_damage() * attack_weight)
	return (health_exp + attack_exp) * level
