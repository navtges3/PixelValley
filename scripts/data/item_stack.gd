extends Resource
class_name ItemStack

@export var item: Item
@export var count: int

func _init(p_item: Item = null, p_count: int = 1) -> void:
	item = p_item
	count = p_count

func get_save_data() -> Dictionary:
	return {
		"item_path": item.resource_path,
		"count": count,
	}

static func create_from_data(data: Dictionary) -> ItemStack:
	var stack = ItemStack.new()
	var path = data.get("item_path", "")
	if path != "":
		stack.item = load(path)
	else:
		stack.item = null
	stack.count = data.get("count", 1)
	return stack