extends CharacterBody2D
class_name Player

const SPEED := 120.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt_label: Label = $PromptLabel
@onready var camera: WorldCamera = get_node_or_null("Camera2D") as WorldCamera

var last_direction := Vector2.DOWN
var _zone_cooldown := false
var movement_blocked := false
var _prompt_owner_id: int = 0

func _ready() -> void:
	prompt_label.hide()
	if camera == null:
		camera = get_node_or_null("Camera2D") as WorldCamera

func get_camera() -> WorldCamera:
	if camera == null:
		camera = get_node_or_null("Camera2D") as WorldCamera
	return camera

func refresh_camera_limits() -> void:
	var cam := get_camera()
	if cam != null:
		cam.refresh_limits()

func enable_player() -> void:
	visible = true
	set_physics_process(true)
	set_process_unhandled_input(true)
	var cam := get_camera()
	if cam != null:
		cam.enabled = true

func disable_player() -> void:
	visible = false
	velocity = Vector2.ZERO
	clear_prompt()
	set_physics_process(false)
	set_process_unhandled_input(false)
	var cam := get_camera()
	if cam != null:
		cam.enabled = false

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
	if _zone_cooldown or zone == null or not is_instance_valid(zone) or zone.locked:
		return
	if ScreenManager.is_transitioning():
		return
	clear_prompt()
	var screen_target := zone.screen_target
	var entrance_id := zone.entrance_id
	var data: Variant = null
	if zone.screen_data >= 0:
		data = zone.screen_data
	_zone_cooldown = true
	ScreenManager.go_to_screen(screen_target, entrance_id, data)
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
