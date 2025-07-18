extends Resource
class_name PotionBelt

@export var potions: Array[PotionStack] = []

func use_potion(potion: Potion) -> Effect:
	for slot in potions:
		if slot.potion == potion and slot.count > 0:
			slot.count -= 1
			return slot.potion.effect
	return null

func add_potion(potion: Potion, amount: int = 1) -> void:
	for slot in potions:
		if slot.potion == potion:
			slot.count += amount
			return
	potions.append(PotionStack.new(potion, amount))