extends Resource
class_name Inventory

@export var gold: int = 0
@export var weapon: Weapon
@export var potions: Array[ItemStack]

func use_potion(potion: Potion) -> Array[Effect]:
	for i in range(potions.size()):
		if potions[i].item == potion:
			var item_stack = potions[i]
			item_stack.count -= 1
			if item_stack.count <= 0:
				print("Removing empty potion slot for %s" % potion.name)
			potions.remove_at(i)
		return potion.effects
	return []

func add_potion(potion: Potion, amount: int = 1) -> void:
	for i in range(potions.size()):
		if potions[i].item == potion:
			potions[i].count += amount
			return
	potions.append(ItemStack.new(potion, amount))
