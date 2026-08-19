extends Resource
class_name DropEntry

@export var item_id: String = ""
@export var chance: float = 1.0
@export var min_count: int = 1
@export var max_count: int = 1

func roll() -> Array:
	if item_id.is_empty():
		push_warning("DropEntry: item_id cannot be empty")
		return []
	var normalized_chance: float = clampf(chance, 0.0, 1.0)
	if normalized_chance <= 0.0 or randf() >= normalized_chance:
		return []
	var low: int = maxi(1, min_count)
	var high: int = maxi(low, max_count)
	return [item_id, randi_range(low, high)]
