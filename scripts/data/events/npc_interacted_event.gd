extends GameplayEvent
class_name NpcInteractedEvent

var npc_id: StringName

func _init(target_npc_id: StringName) -> void:
	npc_id = target_npc_id
