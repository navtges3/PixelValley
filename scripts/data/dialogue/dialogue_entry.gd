extends Resource
class_name DialogueEntry

@export var entry_id: StringName = &""
@export var speaker: DialogueSpeaker
@export var pages: Array[String] = []

@export_category("Flow")
@export var next_entry_id: StringName = &""
@export var skip_entry_id: StringName = &""

@export_category("Conditions and Actions")
@export var conditions: Array[DialogueCondition] = []
@export var actions: Array[DialogueAction] = []
@export var responses: Array[DialogueResponse] = []
