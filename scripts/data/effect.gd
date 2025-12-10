extends Resource
class_name Effect

enum EffectType { HEAL, ENERGY, POISON,
					BUFF_ATTACK, BUFF_MAGIC, BUFF_DEFENSE, BUFF_RESISTANCE,
					DEBUFF_ATTACK, DEBUFF_MAGIC, DEBUFF_DEFENSE, DEBUFF_RESISTANCE }

@export var type: EffectType
@export var strength: int = 0
@export var duration: int = 1

func type_to_string() -> String:
	match type:
		Effect.EffectType.HEAL:
			return "Heal"
		Effect.EffectType.ENERGY:
			return "Recover Energy"
		Effect.EffectType.POISON:
			return "Poison"
		Effect.EffectType.BUFF_ATTACK:
			return "Buff Attack"
		Effect.EffectType.BUFF_MAGIC:
			return "Buff Magic"
		Effect.EffectType.BUFF_DEFENSE:
			return "Buff Defense"
		Effect.EffectType.BUFF_RESISTANCE:
			return "Buff Resistance"
		Effect.EffectType.DEBUFF_ATTACK:
			return "Debuff Attack"
		Effect.EffectType.DEBUFF_MAGIC:
			return "Debuff Magic"
		Effect.EffectType.DEBUFF_DEFENSE:
			return "Debuff Defense"
		Effect.EffectType.DEBUFF_RESISTANCE:
			return "Debuff Resistance"
	return "Unknown"

func is_buff() -> bool:
	return type in [Effect.EffectType.BUFF_ATTACK, Effect.EffectType.BUFF_MAGIC, Effect.EffectType.BUFF_DEFENSE, Effect.EffectType.BUFF_RESISTANCE]

func is_debuff() -> bool:
	return type in [Effect.EffectType.DEBUFF_ATTACK, Effect.EffectType.DEBUFF_MAGIC, Effect.EffectType.DEBUFF_DEFENSE, Effect.EffectType.DEBUFF_RESISTANCE]

func get_tooltip() -> String:
	var name = type_to_string()
	var turn_text = "turn" if duration == 1 else "turns"
	return "%s +%d (%d %s)" % [name, strength, duration, turn_text]

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
