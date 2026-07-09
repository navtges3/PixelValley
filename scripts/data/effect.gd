extends Resource
class_name Effect

enum EffectTiming { ON_APPLY, ON_TICK, ON_EXPIRE }
enum EffectOperation { ADD, SUBTRACT }
enum EffectStat { CURRENT_HP, CURRENT_NRG, MAX_HP, MAX_NRG, ATTACK, MAGIC, DEFENSE, RESIST }

@export var effect_name: String = "Effect"
@export_range(1, 99) var level: int = 1
@export_range(1, 99) var base_duration: int = 1
@export var duration_per_level: int = 0
@export var stat_changes: Array[EffectStatChange] = []

func get_duration() -> int:
	return max(base_duration + ((level - 1) * duration_per_level), 1)

func _to_string(turns_remaining: int = get_duration()) -> String:
	var turn_text := "turn" if turns_remaining == 1 else "turns"
	return "%s %d (%d %s)" % [effect_name, level, turns_remaining, turn_text]
