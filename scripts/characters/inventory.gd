extends Resource
class_name Inventory

@export var gold: int = 0
@export var weapon: Weapon
@export var potions: Array[ItemStack]

func use_potion(potion_stack: ItemStack) -> Array[Effect]:
	var potion := potion_stack.item as Potion
	potion_stack.count -= 1
	if potion_stack.count <= 0:
		print("Removing empty potion slot for %s" % potion_stack.item.name)
		potions.erase(potion_stack)
	return potion.effects

func add_potion(potion: Potion, amount: int = 1) -> void:
	for i in range(potions.size()):
		if potions[i].item.name == potion.name:
			potions[i].count += amount
			return
	potions.append(ItemStack.new(potion, amount))
