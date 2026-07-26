extends QuestObjective
class_name DeliveryQuestObjective

@export var target_npc_id: StringName = &""
@export var item_id: String = ""
@export_range(1, 999, 1) var target_amount: int = 1
@export var current_amount: int = 0

func apply_event(event: GameplayEvent) -> bool:
	if is_complete() or not event is ItemDeliveredEvent:
		return false
	var delivery := event as ItemDeliveredEvent
	if delivery.npc_id != target_npc_id:
		return false
	if delivery.item_id != item_id:
		return false
	current_amount = mini(current_amount + delivery.amount, target_amount)
	return delivery.amount > 0

func is_complete() -> bool:
	return current_amount >= target_amount

func reset_progress() -> void:
	current_amount = 0

func get_objective_type() -> String:
	return "delivery"
