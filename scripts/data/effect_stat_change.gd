extends Resource
class_name EffectStatChange

@export var stat: Effect.EffectStat
@export var timing: Effect.EffectTiming
@export var operation: Effect.EffectOperation = Effect.EffectOperation.ADD
@export var base_amount: int = 0
@export var amount_per_level: int = 0
@export var scales_with_level: bool = false

func get_amount(level: int) -> int:
	if not scales_with_level:
		return base_amount
	return base_amount + ((level - 1) * amount_per_level)
