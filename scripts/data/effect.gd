extends Resource
class_name Effect

enum EffectType { HEAL, ENERGY, POISON,
					BUFF_ATTACK, BUFF_MAGIC, BUFF_DEFENSE, BUFF_RESISTANCE,
					DEBUFF_ATTACK, DEBUFF_MAGIC, DEBUFF_DEFENSE, DEBUFF_RESISTANCE }

@export var type: EffectType
@export var strength: int = 0
@export var duration: int = 1

func is_buff() -> bool:
	return type in [Effect.EffectType.BUFF_ATTACK, Effect.EffectType.BUFF_MAGIC, Effect.EffectType.BUFF_DEFENSE, Effect.EffectType.BUFF_RESISTANCE]

func is_debuff() -> bool:
	return type in [Effect.EffectType.DEBUFF_ATTACK, Effect.EffectType.DEBUFF_MAGIC, Effect.EffectType.DEBUFF_DEFENSE, Effect.EffectType.DEBUFF_RESISTANCE]

func _to_string() -> String:
	var turn_text = "turn" if duration == 1 else "turns"
	match type:
		Effect.EffectType.HEAL:
			return "Heal %d (%d %s)" % [strength, duration, turn_text]
		Effect.EffectType.ENERGY:
			return "Recover Energy %d (%d %s)" % [strength, duration, turn_text]
		Effect.EffectType.POISON:
			return "Poison %d (%d %s)" % [strength, duration, turn_text]
		Effect.EffectType.BUFF_ATTACK:
			return "Attack +%d (%d %s)" % [strength, duration, turn_text]
		Effect.EffectType.BUFF_MAGIC:
			return "Magic +%d (%d %s)" % [strength, duration, turn_text]
		Effect.EffectType.BUFF_DEFENSE:
			return "Defense +%d (%d %s)" % [strength, duration, turn_text]
		Effect.EffectType.BUFF_RESISTANCE:
			return "Resistance +%d (%d %s)" % [strength, duration, turn_text]
		Effect.EffectType.DEBUFF_ATTACK:
			return "Attack -%d (%d %s)" % [strength, duration, turn_text]
		Effect.EffectType.DEBUFF_MAGIC:
			return "Magic -%d (%d %s)" % [strength, duration, turn_text]
		Effect.EffectType.DEBUFF_DEFENSE:
			return "Defense -%d (%d %s)" % [strength, duration, turn_text]
		Effect.EffectType.DEBUFF_RESISTANCE:
			return "Resistance -%d (%d %s)" % [strength, duration, turn_text]
	return "Unknown"

func get_button_theme() -> Theme:
	match type:
		Effect.EffectType.HEAL:
			return preload("res://assets/button_themes/regular/green_button.tres")
		Effect.EffectType.ENERGY:
			return preload("res://assets/button_themes/regular/yellow_button.tres")
		Effect.EffectType.POISON:
			return preload("res://assets/button_themes/regular/green_button.tres")
		Effect.EffectType.BUFF_ATTACK:
			return preload("res://assets/button_themes/regular/red_button.tres")
		Effect.EffectType.BUFF_MAGIC:
			return preload("res://assets/button_themes/regular/red_button.tres")
		Effect.EffectType.BUFF_DEFENSE:
			return preload("res://assets/button_themes/regular/blue_button.tres")
		Effect.EffectType.BUFF_RESISTANCE:
			return preload("res://assets/button_themes/regular/blue_button.tres")
		Effect.EffectType.DEBUFF_ATTACK:
			return preload("res://assets/button_themes/regular/red_button.tres")
		Effect.EffectType.DEBUFF_MAGIC:
			return preload("res://assets/button_themes/regular/red_button.tres")
		Effect.EffectType.DEBUFF_DEFENSE:
			return preload("res://assets/button_themes/regular/blue_button.tres")
		Effect.EffectType.DEBUFF_RESISTANCE:
			return preload("res://assets/button_themes/regular/blue_button.tres")
	return preload("res://assets/button_themes/regular/gray_button.tres")
