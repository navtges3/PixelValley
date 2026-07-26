extends Resource
class_name NpcData

@export_category("Identity")
@export var npc_id: StringName = &""
@export var display_name: String = ""

@export_category("Presentation")
@export var world_visual: SpriteFrames
@export var portrait: Texture2D

@export_category("Interaction")
@export var dialogue: DialogueConversation
@export var service_id: StringName = &""

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if npc_id.is_empty():
		errors.append("NPC ID cannot be empty.")
	if display_name.is_empty():
		errors.append("NPC '%s' has no display name." % npc_id)
	if world_visual == null:
		errors.append("NPC '%s' has no world visual." % npc_id)
	if dialogue == null and service_id.is_empty():
		errors.append("NPC '%s' has neither dialogue nor a service." % npc_id)
	return errors
