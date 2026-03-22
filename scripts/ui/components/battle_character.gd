extends Node2D
class_name BattleCharacter

const Y_OFFSET := 64
const SPRITE_SCALE := Vector2(3.0, 3.0)

@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
signal animation_done()

func set_frames(frames: SpriteFrames) -> void:
	sprite.sprite_frames = frames
	sprite.play("idle")

func apply_visual(visual: BattleVisualData, flip_h := false) -> void:
	sprite.sprite_frames = visual.frames
	sprite.scale = SPRITE_SCALE
	print("Sprite size", sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame).get_size())
	sprite.flip_h = flip_h
	sprite.position.y -= (visual.sprite_height - Y_OFFSET)
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

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation != "idle" and sprite.animation != "death":
		sprite.play("idle")
	emit_signal("animation_done")
