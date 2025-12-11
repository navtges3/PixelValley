extends Item
class_name Potion

@export var effects: Array[Effect]

func _to_string() -> String:
	var tip = "%s" % name
	for effect in effects:
		tip += "\n%s" % effect._to_string()
	return tip
