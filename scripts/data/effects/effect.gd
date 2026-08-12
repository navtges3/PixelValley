extends Resource
class_name Effect

enum EffectTiming { ON_APPLY, ON_TICK, ON_EXPIRE, ON_REMOVE }
enum Persistence { COMBAT_ONLY, PERSISTENT }
enum EffectOperation { ADD, SUBTRACT }
enum EffectStat { CURRENT_HP, CURRENT_NRG, MAX_HP, MAX_NRG, ATTACK, MAGIC, DEFENSE, RESIST }

@export var effect_name: String = "Effect"
@export var effect_id: StringName = &""
@export var image: Texture2D
@export var persistence: Persistence = Persistence.COMBAT_ONLY
@export_range(1, 99) var level: int = 1
@export_range(1, 99) var base_duration: int = 1
@export var duration_per_level: int = 0
@export var is_instant: bool = false
@export var stat_changes: Array[EffectStatChange] = []

func get_duration() -> int:
	return max(base_duration + ((level - 1) * duration_per_level), 1)

static func is_modifier_stat(stat: EffectStat) -> bool:
	return stat not in [EffectStat.CURRENT_HP, EffectStat.CURRENT_NRG]

func _to_string(turns_remaining: int = get_duration()) -> String:
	var turn_text := "turn" if turns_remaining == 1 else "turns"
	return "%s %d (%d %s)" % [effect_name, level, turns_remaining, turn_text]
