extends Resource
class_name Inventory

@export var gold: int = 0
@export var weapon: Weapon
@export var potions: Array[ItemStack]

func use_potion(potion: Potion) -> Effect:
	var index = potions.find(potion)
	if index != -1:
		var item_stack = potions[index]
		item_stack.count -= 1
		if item_stack.count <= 0:
			print("Removing empty potion slot for %s" % potion.name)
			potions.remove_at(index)
		return potion.effect
	return null

func add_potion(potion: Potion, amount: int = 1) -> void:
	var index = potions.find(potion)
	if index != -1:
		potions[index].count += amount
	else:
		potions.append(ItemStack.new(potion, amount))
