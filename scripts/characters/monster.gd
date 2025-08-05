extends Resource
class_name Monster

@export var name: String
@export var max_hp: int
@export var current_hp: int
@export var attack: int
@export var gold: int
@export var portrait: Texture2D = null

func take_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)

func is_alive() -> bool:
	return current_hp > 0

func calculate_experience() -> int:
	var health_weight := 0.5
	var attack_weight := 0.75
	var health_exp := int(current_hp * health_weight)
	var attack_exp := int(attack * attack_weight)
	return (health_exp + attack_exp)
