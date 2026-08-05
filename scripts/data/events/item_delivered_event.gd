extends GameplayEvent
class_name ItemDeliveredEvent

var npc_id: StringName
var item_id: String
var amount: int

func _init(target_npc_id: StringName, delivered_item_id: String, delivered_amount: int) -> void:
	npc_id = target_npc_id
	item_id = delivered_item_id
	amount = delivered_amount
