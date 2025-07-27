extends Item
class_name Potion

@export var effect: Effect

func get_tooltip() -> String:
	return "%s\n%s" % [name, effect.get_tooltip()]