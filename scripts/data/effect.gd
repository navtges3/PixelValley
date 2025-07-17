extends Resource
class_name Effect
@export var type: String = ""
@export var strength: int = 0
@export var duration: int = 1

func get_tooltip() -> String:
	if duration > 1:
		return "%s %d, %d turns" % [type, strength, duration]
	else:
		return "%s %d, %d turn" % [type, strength, duration]
