extends Resource
class_name Inventory

@export var gold: int = 0
@export var equipped_weapon: Weapon
@export var weapon_stash: Array[Weapon]
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

func equip_weapon(weapon: Weapon) -> void:
	if equipped_weapon:
		weapon_stash.append(equipped_weapon)
	equipped_weapon = weapon
	weapon_stash.erase(weapon)

func add_weapon_to_stash(weapon: Weapon) -> void:
	if weapon not in weapon_stash and weapon != equipped_weapon:
		weapon_stash.append(weapon)
	else:
		gold += weapon.value

func remove_weapon_from_stash(weapon: Weapon) -> void:
	weapon_stash.erase(weapon)
