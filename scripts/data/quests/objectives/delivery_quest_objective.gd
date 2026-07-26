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
	if delivery.amount <= 0:
		return false
	if delivery.npc_id != target_npc_id:
		return false
	if delivery.item_id != item_id:
		return false
	current_amount = mini(current_amount + delivery.amount, target_amount)
	return true

func is_complete() -> bool:
	return current_amount >= target_amount

func reset_progress() -> void:
	current_amount = 0

func get_progress_text() -> String:
	var item := ItemLoader.get_item(item_id)
	var item_name: String = item.name if item != null else item_id
	return "Deliver %s to %s: %d/%d" % [
		item_name,
		String(target_npc_id).replace("_", " ").capitalize(),
		current_amount,
		target_amount,
	]

func get_save_data() -> Dictionary:
	return {
		"type": get_objective_type(),
		"target_npc_id": String(target_npc_id),
		"item_id": item_id,
		"target_amount": target_amount,
		"current_amount": current_amount,
	}

func load_save_data(data: Dictionary) -> void:
	target_npc_id = StringName(str(data.get("target_npc_id", "")))
	item_id = str(data.get("item_id", ""))
	target_amount = maxi(int(data.get("target_amount", 1)), 1)
	current_amount = clampi(
		int(data.get("current_amount", 0)),
		0,
		target_amount
	)

func get_objective_type() -> String:
	return "delivery"
