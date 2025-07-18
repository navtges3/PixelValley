extends Resource
class_name PotionStack

@export var potion: Potion
@export var count: int

func _init(p_potion: Potion = null, p_count: int = 1) -> void:
	potion = p_potion
	count = p_count