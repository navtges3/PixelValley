extends Resource
class_name Effect

enum EffectType { HEAL, ENERGY, BUFF_ATTACK }

@export var type: EffectType
@export var strength: int = 0
@export var duration: int = 1

func type_to_string() -> String:
	match type:
		Effect.EffectType.HEAL:
			return "Heal"
		Effect.EffectType.ENERGY:
			return "Recover Energy"
		Effect.EffectType.BUFF_ATTACK:
			return "Buff Attack"
	return "Unknown"

func get_tooltip() -> String:
	if duration > 1:
		return "%s %d, %d turns" % [self.type_to_string(), strength, duration]
	else:
		return "%s %d, %d turn" % [self.type_to_string(), strength, duration]

func get_button_theme() -> Theme:
	match type:
		Effect.EffectType.HEAL:
			return preload("res://assets/button_themes/large/large_green_button.tres")
		Effect.EffectType.ENERGY:
			return preload("res://assets/button_themes/large/large_blue_button.tres")
		Effect.EffectType.BUFF_ATTACK:
			return preload("res://assets/button_themes/large/large_red_button.tres")
	return preload("res://assets/button_themes/large/large_gray_button.tres")