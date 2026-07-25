extends Resource
class_name DialogueResponse

@export var text: String = ""
@export var next_entry_id: StringName = &""
@export var conditions: Array[DialogueCondition] = []
@export var actions: Array[DialogueAction] = []
