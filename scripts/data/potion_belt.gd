extends Resource
class_name PotionBelt

@export var potions: Array[ItemStack] = []

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
	potions.append(ItemStack.new(potion, amount))

func get_potions() -> Array[Potion]:
	var arr: Array[Potion] = []
	for slot in potions:
		if slot.count > 0:
			arr.append(slot.potion)
	return arr

func has_potions() -> bool:
	for slot in potions:
		if slot.count > 0:
			return true
	return false

func get_save_data() -> Dictionary:
	var potion_data_array: Array = []
	for slot in potions:
		potion_data_array.append(slot.get_save_data())
	return {
		"potions": potion_data_array
	}

static func create_from_data(data: Dictionary) -> PotionBelt:
	var belt = PotionBelt.new()
	var saved_potions: Array = data.get("potions", [])
	for slot_data in saved_potions:
		belt.potions.append(ItemStack.create_from_data(slot_data))
	return belt