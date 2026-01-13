extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	if sprite.animation != "idle":
		sprite.play("idle")

func set_frames(frames: SpriteFrames) -> void:
	sprite.sprite_frames = frames
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

func play_block() -> void:
	if sprite.animation != "block":
		sprite.play("block")
