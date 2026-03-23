extends CharacterBody2D

const SPEED := 120.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var last_direction := Vector2.DOWN

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
