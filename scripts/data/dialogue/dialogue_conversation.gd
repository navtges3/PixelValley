extends Resource
class_name DialogueConversation

@export var conversation_id: StringName = &""
@export var start_entry_id: StringName = &""
@export var can_cancel: bool = true
@export var entries: Array[DialogueEntry] = []
