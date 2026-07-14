extends Resource
class_name EffectStatChange

@export var stat: Effect.EffectStat
@export var timing: Effect.EffectTiming
@export var operation: Effect.EffectOperation = Effect.EffectOperation.ADD
@export var base_amount: int = 0
@export var amount_per_level: int = 0

func get_amount(level: int) -> int:
	if amount_per_level > 0:
		return base_amount + ((level - 1) * amount_per_level)
	return base_amount

func get_signed_amount(level: int) -> int:
	var amount := get_amount(level)
	return amount if operation == Effect.EffectOperation.ADD else -amount

func is_modifier() -> bool:
	return Effect.is_modifier_stat(stat)

func is_reversible_modifier() -> bool:
	return timing == Effect.EffectTiming.ON_APPLY and is_modifier()
