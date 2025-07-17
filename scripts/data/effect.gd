extends Resource
class_name Effect

enum EffectType { HEAL, BUFF_ATTACK }

@export var type: EffectType
@export var strength: int = 0
@export var duration: int = 1

func type_to_string() -> String:
	match type:
		Effect.EffectType.HEAL:
			return "Heal"
		Effect.EffectType.BUFF_ATTACK:
			return "Buff Attack"
	return "Unknown"

func get_tooltip() -> String:
	if duration > 1:
		return "%s %d, %d turns" % [self.type_to_string(), strength, duration]
	else:
		return "%s %d, %d turn" % [self.type_to_string(), strength, duration]
