extends Resource
class_name DropEntry

@export var item_id: String = ""
@export var chance: float = 1.0
@export var min_count: int = 1
@export var max_count: int = 1

func roll() -> Array:
	if randf() > chance:
		return []
	var count := randi_range(min_count, max_count)
	return [item_id, count]
