extends Resource
class_name NpcData

enum ContentStatus {
	MISSING,
	PLACEHOLDER,
	FINAL,
}

@export_category("Identity")
@export var npc_id: StringName = &""
@export var display_name: String = ""
@export var role: String = ""
@export var location_id: StringName = &""

@export_category("Presentation")
@export var world_visual: SpriteFrames
@export var world_visual_status: ContentStatus = ContentStatus.PLACEHOLDER
@export var portrait: Texture2D
@export var portrait_status: ContentStatus = ContentStatus.MISSING

@export_category("Interaction")
@export var dialogue: DialogueConversation
@export var service_id: StringName = &""
@export var quest_ids: Array[int] = []

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if npc_id.is_empty():
		errors.append("NPC ID cannot be empty.")
	if display_name.is_empty():
		errors.append("NPC '%s' has no display name." % npc_id)
	if role.is_empty():
		errors.append("NPC '%s' has no documented role." % npc_id)
	if location_id.is_empty():
		errors.append("NPC '%s' has no documented location." % npc_id)
	if world_visual == null:
		errors.append("NPC '%s' has no world visual." % npc_id)
	if portrait_status != ContentStatus.MISSING and portrait == null:
		errors.append("NPC '%s' has a portrait status but no portrait." % npc_id)
	if dialogue == null and service_id.is_empty():
		errors.append("NPC '%s' has neither dialogue nor a service." % npc_id)
	if dialogue != null and dialogue.conversation_id.is_empty():
		errors.append("NPC '%s' has dialogue with no stable conversation ID." % npc_id)
	return errors
