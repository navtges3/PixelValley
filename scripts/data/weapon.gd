extends Resource

class_name Weapon

@export var name: String
@export var rarity: String
@export var abilities: Array[Ability] = []

func update_cooldown() -> void:
	for ability in abilities:
		ability.update_cooldown()