extends Resource
class_name Shop

@export var name: String
@export var inventory: Dictionary = {}

func has_inventory() -> bool:
	return not inventory.is_empty()

func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + count

func remove_item(item_id: String, count: int = 1) -> void:
	if not inventory.has(item_id):
		push_warning("Shop: item '%s' not in inventory" % item_id)
		return
	inventory[item_id] -= count
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
