extends Node2D
class_name BattleCharacter

const Y_OFFSET := 64
const SCALE := Vector2(3.0, 3.0)

@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var weapon_anchor: Marker2D = $Visual/WeaponAnchor
@onready var weapon_sprite: Sprite2D = $Visual/WeaponAnchor/WeaponSprite

signal animation_done()

var _hand_positions: Dictionary = {}
var _flip_h := false

func set_frames(frames: SpriteFrames) -> void:
	sprite.sprite_frames = frames
	sprite.play("idle")

func apply_visual(combatant: Combatant, flip_h := false) -> void:
	sprite.sprite_frames = combatant.battle_visual
	scale = SCALE
	sprite.position.y -= (combatant.battle_height - Y_OFFSET)
	sprite.flip_h = flip_h
	sprite.play("idle")
	
	_flip_h = flip_h
	_hand_positions = combatant.hand_positions
	
	weapon_anchor.scale.x = -1.0 if flip_h else 1.0
	_update_weapon_anchor()

func equip_weapon(weapon_texture: Texture2D) -> void:
	if weapon_texture == null or _hand_positions.is_empty():
		weapon_sprite.visible = false
		return
	weapon_sprite.texture = weapon_texture
	weapon_sprite.visible = true
	_update_weapon_anchor()

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

func _on_frame_changed():
	_update_weapon_anchor()

func _update_weapon_anchor() -> void:
	if _hand_positions.is_empty():
		weapon_sprite.visible = false
		return
	
	var anim := sprite.animation
	var frame := sprite.frame
	
	if not _hand_positions.has(anim):
		return
	
	var positions: Array = _hand_positions[anim]
	
	if frame >= positions.size():
		push_warning("BattleCharacter: hand_positions[\"%s\"] has %d entries but frame %d was requested" % [anim, positions.size(), frame])
		return
	
	weapon_anchor.position = positions[frame]

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation != "idle" and sprite.animation != "death":
		sprite.play("idle")
	emit_signal("animation_done")
