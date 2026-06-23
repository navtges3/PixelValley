extends Resource
class_name Effect

enum EffectType { HEAL, ENERGY, POISON,
					BUFF_ATTACK, BUFF_MAGIC, BUFF_DEFENSE, BUFF_RESIST,
					DEBUFF_ATTACK, DEBUFF_MAGIC, DEBUFF_DEFENSE, DEBUFF_RESIST }

const THEME_PATHS: Dictionary = {
	Effect.EffectType.HEAL:             "res://resources/themes/buttons/regular/green_button.tres",
	Effect.EffectType.ENERGY:           "res://resources/themes/buttons/regular/yellow_button.tres",
	Effect.EffectType.POISON:           "res://resources/themes/buttons/regular/green_button.tres",
	Effect.EffectType.BUFF_ATTACK:      "res://resources/themes/buttons/regular/red_button.tres",
	Effect.EffectType.BUFF_MAGIC:       "res://resources/themes/buttons/regular/red_button.tres",
	Effect.EffectType.BUFF_DEFENSE:     "res://resources/themes/buttons/regular/blue_button.tres",
	Effect.EffectType.BUFF_RESIST:      "res://resources/themes/buttons/regular/blue_button.tres",
	Effect.EffectType.DEBUFF_ATTACK:    "res://resources/themes/buttons/regular/red_button.tres",
	Effect.EffectType.DEBUFF_MAGIC:     "res://resources/themes/buttons/regular/red_button.tres",
	Effect.EffectType.DEBUFF_DEFENSE:   "res://resources/themes/buttons/regular/blue_button.tres",
	Effect.EffectType.DEBUFF_RESIST:    "res://resources/themes/buttons/regular/blue_button.tres",
}

@export var type: EffectType
@export var strength: int = 0
@export var duration: int = 1

func is_buff() -> bool:
	return type in [Effect.EffectType.BUFF_ATTACK, Effect.EffectType.BUFF_MAGIC, Effect.EffectType.BUFF_DEFENSE, Effect.EffectType.BUFF_RESIST]

func is_debuff() -> bool:
	return type in [Effect.EffectType.DEBUFF_ATTACK, Effect.EffectType.DEBUFF_MAGIC, Effect.EffectType.DEBUFF_DEFENSE, Effect.EffectType.DEBUFF_RESIST]

func _to_string(turns_remaining: int = duration) -> String:
	var turn_text := "turn" if turns_remaining == 1 else "turns"
	var type_text := ""
	match type:
		Effect.EffectType.HEAL:
			type_text = "Heal %d" % strength
		Effect.EffectType.ENERGY:
			type_text = "Recover Energy %d" % strength
		Effect.EffectType.POISON:
			type_text = "Poison %d" % strength
		Effect.EffectType.BUFF_ATTACK:
			type_text = "Attack +%d" % strength
		Effect.EffectType.BUFF_MAGIC:
			type_text = "Magic +%d" % strength
		Effect.EffectType.BUFF_DEFENSE:
			type_text = "Defense +%d" % strength
		Effect.EffectType.BUFF_RESIST:
			type_text = "Resist +%d" % strength
		Effect.EffectType.DEBUFF_ATTACK:
			type_text = "Attack -%d" % strength
		Effect.EffectType.DEBUFF_MAGIC:
			type_text = "Magic -%d" % strength
		Effect.EffectType.DEBUFF_DEFENSE:
			type_text = "Defense -%d" % strength
		Effect.EffectType.DEBUFF_RESIST:
			type_text = "Resist -%d" % strength
	if type_text == "":
		type_text = "Unknown"
	return "%s (%d %s)" % [type_text, turns_remaining, turn_text]

func get_button_theme() -> Theme:
	var path: String = THEME_PATHS.get(type, "res://resources/themes/buttons/regular/gray_button.tres")
	return load(path) as Theme
