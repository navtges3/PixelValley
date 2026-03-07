extends Node2D

@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D

signal animation_done()

func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	if sprite.animation != "idle" and sprite.animation != "death":
		sprite.play("idle")
	emit_signal("animation_done")

func set_frames(frames: SpriteFrames) -> void:
	sprite.sprite_frames = frames
	sprite.play("idle")

func apply_visual(visual: BattleVisualData) -> void:
	sprite.sprite_frames = visual.frames
	sprite.scale = visual.scale
	sprite.position.y = -visual.sprite_height
	sprite.play("idle")

func play_idle() -> void:
	if sprite.animation != "idle":
		sprite.play("idle")

func play_attack() -> void:
	if sprite.animation != "attack":
		sprite.play("attack")

func play_hurt() -> void:
	if sprite.animation != "hurt":
		sprite.play("hurt")

func play_death() -> void:
	if sprite.animation != "death":
		sprite.play("death")
