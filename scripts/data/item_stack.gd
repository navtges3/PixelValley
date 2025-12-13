extends Resource
class_name ItemStack

@export var item: Item
@export var count: int

func _init(p_item: Item = null, p_count: int = 1) -> void:
	item = p_item
	count = p_count
