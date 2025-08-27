extends Item
class_name Potion

@export var effects: Array[Effect]

func get_tooltip() -> String:
	var tip = "%s\n" % name
	for effect in effects:
		tip += "%s\n" % effect.get_tooltip()
	return tip
