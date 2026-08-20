extends CharacterBody2D
class_name Player

const SPEED := 120.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt_label: Label = $PromptLabel

var last_direction := Vector2.DOWN
var _zone_cooldown := false
var movement_blocked := false
var _prompt_owner_id: int = 0

func _ready() -> void:
	prompt_label.hide()

func _physics_process(_delta: float) -> void:
	if movement_blocked:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()

	velocity = input * SPEED
	move_and_slide()
	_update_animation(input)

func _update_animation(input: Vector2) -> void:
	if input == Vector2.ZERO:
		anim.stop()
		return

	last_direction = input

	if abs(input.x) > abs(input.y):
		anim.play("walk_right" if input.x > 0 else "walk_left")
	else:
		anim.play("walk_down" if input.y > 0 else "walk_up")

func on_zone_entered(zone: TriggerZone) -> void:
	print("Player entered zone: %s" % zone.name)
	if _zone_cooldown or zone.locked:
		return
	clear_prompt()
	_zone_cooldown = true
	await get_tree().process_frame
	var data: Variant = null
	if zone.screen_data >= 0:
		data = zone.screen_data
	ScreenManager.go_to_screen(zone.screen_target, zone.entrance_id, data)
	_zone_cooldown = false

func place_at_entrance(entrance_node: Node2D) -> void:
	global_position = entrance_node.global_position

func set_sprite_frames(frames: SpriteFrames) -> void:
	if frames:
		anim.sprite_frames = frames

func show_prompt(message: String, source: Object = null) -> void:
	if message.is_empty():
		return
	_prompt_owner_id = source.get_instance_id() if source != null else 0
	prompt_label.text = message
	prompt_label.show()

func clear_prompt(message: String = "", source: Object = null) -> void:
	if source != null and _prompt_owner_id != source.get_instance_id():
		return
	if not message.is_empty() and prompt_label.text != message:
		return
	_prompt_owner_id = 0
	prompt_label.text = ""
	prompt_label.hide()
