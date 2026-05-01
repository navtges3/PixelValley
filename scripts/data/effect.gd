extends Resource
class_name Effect

enum EffectType { HEAL, ENERGY, POISON,
					BUFF_ATTACK, BUFF_MAGIC, BUFF_DEFENSE, BUFF_RESISTANCE,
					DEBUFF_ATTACK, DEBUFF_MAGIC, DEBUFF_DEFENSE, DEBUFF_RESISTANCE }

const THEME_PATHS: Dictionary = {
	Effect.EffectType.HEAL:             "res://resources/ui/button_themes/regular/green_button.tres",
	Effect.EffectType.ENERGY:           "res://resources/ui/button_themes/regular/yellow_button.tres",
	Effect.EffectType.POISON:           "res://resources/ui/button_themes/regular/green_button.tres",
	Effect.EffectType.BUFF_ATTACK:      "res://resources/ui/button_themes/regular/red_button.tres",
	Effect.EffectType.BUFF_MAGIC:       "res://resources/ui/button_themes/regular/red_button.tres",
	Effect.EffectType.BUFF_DEFENSE:     "res://resources/ui/button_themes/regular/blue_button.tres",
	Effect.EffectType.BUFF_RESISTANCE:  "res://resources/ui/button_themes/regular/blue_button.tres",
	Effect.EffectType.DEBUFF_ATTACK:    "res://resources/ui/button_themes/regular/red_button.tres",
	Effect.EffectType.DEBUFF_MAGIC:     "res://resources/ui/button_themes/regular/red_button.tres",
	Effect.EffectType.DEBUFF_DEFENSE:   "res://resources/ui/button_themes/regular/blue_button.tres",
	Effect.EffectType.DEBUFF_RESISTANCE:"res://resources/ui/button_themes/regular/blue_button.tres",
}

@export var type: EffectType
@export var strength: int = 0
@export var duration: int = 1

func is_buff() -> bool:
	return type in [Effect.EffectType.BUFF_ATTACK, Effect.EffectType.BUFF_MAGIC, Effect.EffectType.BUFF_DEFENSE, Effect.EffectType.BUFF_RESISTANCE]

func is_debuff() -> bool:
	return type in [Effect.EffectType.DEBUFF_ATTACK, Effect.EffectType.DEBUFF_MAGIC, Effect.EffectType.DEBUFF_DEFENSE, Effect.EffectType.DEBUFF_RESISTANCE]

func _to_string(turns_remaining := duration) -> String:
	var turn_text = "turn" if turns_remaining == 1 else "turns"
	var type_text = ""
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
		Effect.EffectType.BUFF_RESISTANCE:
			type_text = "Resistance +%d" % strength
		Effect.EffectType.DEBUFF_ATTACK:
			type_text = "Attack -%d" % strength
		Effect.EffectType.DEBUFF_MAGIC:
			type_text = "Magic -%d" % strength
		Effect.EffectType.DEBUFF_DEFENSE:
			type_text = "Defense -%d" % strength
		Effect.EffectType.DEBUFF_RESISTANCE:
			type_text = "Resistance -%d" % strength
	if type_text == "":
		type_text = "Unknown"
	return "%s (%d %s)" % [type_text, turns_remaining, turn_text]

func get_button_theme() -> Theme:
	var path = THEME_PATHS.get(type, "res://resources/ui/button_themes/regular/gray_button.tres")
	return load(path) as Theme
