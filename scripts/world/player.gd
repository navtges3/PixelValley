extends CharacterBody2D

const SPEED := 120.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var last_direction := Vector2.DOWN
var _zone_cooldown := false

func _physics_process(_delta: float) -> void:
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
	if _zone_cooldown or zone.locked:
		return
	_zone_cooldown = true
	await get_tree().process_frame
	ScreenManager.go_to_screen(zone.screen_target, zone.entrance_id)
	_zone_cooldown = false

func place_at_entrance(entrance_node: Node2D) -> void:
	global_position = entrance_node.global_position
