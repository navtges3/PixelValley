extends Resource
class_name Shop

@export var name: String
@export var inventory: Array[ItemStack] = []

func has_inventory() -> bool:
	return inventory.size() > 0

func add_item(item: Item, count: int = 1) -> void:
	for item_stack: ItemStack in inventory:
		if item == item_stack.item:
			item_stack.count += count
			return
	var new_item := ItemStack.new(item, count)
	inventory.append(new_item)

func get_save_data() -> Dictionary:
	var inventory_data_array: Array = []
	for item_stack in inventory:
		inventory_data_array.append(item_stack.get_save_data())
	return {
		"name": name,
		"inventory": inventory_data_array,
	}

static func create_from_data(data: Dictionary) -> Shop:
	var shop = Shop.new()
	shop.name = data.get("name", "Default Shop")
	var saved_inventory: Array = data.get("inventory", [])
	for item_stack in saved_inventory:
		shop.inventory.append(ItemStack.create_from_data(item_stack))
	return shop