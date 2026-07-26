extends CharacterBody2D
class_name NpcActor

enum Facing { DOWN, LEFT, RIGHT, UP }
enum Status { NONE, NEW_CONVERSATION, QUEST_AVAILABLE, QUEST_READY }

signal dialogue_requested(npc_id: StringName, conversation: DialogueConversation)
signal service_requested(npc_id: StringName, service_id: StringName)
signal status_changed(status: Status)

@export var data: NpcData
@export var prompt_text: String = "Press E to Talk"
@export var interaction_offset: Vector2 = Vector2.ZERO
@export var facing: Facing = Facing.DOWN:
	set(value):
		facing = value
		if is_node_ready():
			_apply_facing()

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: InteractArea = $InteractArea
@onready var status_indicator: Label = $StatusIndicator

var status: Status = Status.NONE

func _ready() -> void:
	# This actor has no AI or per-frame behavior.
	set_process(false)
	set_physics_process(false)
	interact_area.prompt_text = prompt_text
	interact_area.position = interaction_offset
	interact_area.interacted.connect(_on_interacted)
	if not _apply_data():
		interact_area.set_enabled(false)
		return
	_apply_facing()
	set_status(Status.NONE)

func set_status(new_status: Status) -> void:
	var changed := status != new_status
	status = new_status
	match status:
		Status.NONE:
			status_indicator.text = ""
			status_indicator.hide()
		Status.NEW_CONVERSATION:
			status_indicator.text = "!"
			status_indicator.show()
		Status.QUEST_AVAILABLE:
			status_indicator.text = "?"
			status_indicator.show()
		Status.QUEST_READY:
			status_indicator.text = "✓"
			status_indicator.show()
	if changed:
		status_changed.emit(status)

func _apply_data() -> bool:
	if data == null:
		push_error("NpcActor '%s' has no NpcData." % name)
		return false
	var errors := data.get_validation_errors()
	for error: String in errors:
		push_error(error)
	if not errors.is_empty():
		return false
	animated_sprite.sprite_frames = data.world_visual
	return true

func _apply_facing() -> void:
	if data == null or animated_sprite.sprite_frames == null:
		return
	var animation_name := _get_facing_animation()
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		push_warning("NPC '%s' is missing animation '%s'." % [data.npc_id, animation_name])
		return
	animated_sprite.play(animation_name)

func _get_facing_animation() -> StringName:
	match facing:
		Facing.LEFT:
			return &"idle_left"
		Facing.RIGHT:
			return &"idle_right"
		Facing.UP:
			return &"idle_up"
		_:
			return &"idle_down"

func _on_interacted() -> void:
	if data == null:
		return
	if data.dialogue != null:
		dialogue_requested.emit(data.npc_id, data.dialogue)
	elif not data.service_id.is_empty():
		service_requested.emit(data.npc_id, data.service_id)
