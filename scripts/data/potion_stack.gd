extends Resource
class_name PotionStack

@export var potion: Potion
@export var count: int

func _init(p_potion: Potion = null, p_count: int = 1) -> void:
	potion = p_potion
	count = p_count

func get_save_data() -> Dictionary:
	return {
		"potion_path": potion.resource_path if potion else "",
		"count": count,
	}

static func create_from_data(data: Dictionary) -> PotionStack:
	var stack = PotionStack.new()
	var path = data.get("potion_path", "")
	if path != "":
		stack.potion = load(path) as Potion
	else:
		stack.potion = null
	stack.count = data.get("count", 0)
	return stack