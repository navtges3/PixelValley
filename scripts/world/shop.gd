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

func remove_item(item: Item, count: int = 1) -> void:
	for item_stack: ItemStack in inventory:
		if item == item_stack.item:
			item_stack.count -= count
			if item_stack.count <= 0:
				inventory.erase(item_stack)
			return
	print("Item %s not found in shop inventory." % item.name)