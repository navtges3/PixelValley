extends Node2D
class_name BattleCharacter

const SCALE := Vector2(3.0, 3.0)
const EFFECT_ICON_SIZE := Vector2(16.0, 16.0)
const STATUS_PLATE_GAP := 20.0 # screen px below origin, clears the floor disc
const ACTIVE_RING_RADIUS := Vector2(22.0, 10.0) # fits the 48x24 floor
const ACTIVE_RING_CENTER := Vector2(0.0, -6.0)
const ACTIVE_RING_COLOR := Color(1.0, 0.85, 0.3)
const ACTIVE_RING_POINTS := 32
const DEFEATED_MODULATE := Color(0.45, 0.45, 0.45, 0.7)

signal target_selected(combatant: Combatant)

@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var weapon_anchor: Marker2D = $Visual/WeaponAnchor
@onready var weapon_sprite: Sprite2D = $Visual/WeaponAnchor/WeaponSprite
@onready var magic_glow: MagicGlow = $Visual/WeaponAnchor/MagicGlow
@onready var tip_point: Node2D = $Visual/WeaponAnchor/TipPoint
@onready var weapon_trail: WeaponTrail = $Visual/WeaponTrail
@onready var effects_container: HBoxContainer = $EffectsCenter/EffectsContainer
@onready var target_hitbox: Button = $TargetHitbox
@onready var visual_root: Node2D = $Visual
@onready var status_plate: BattleStatusPlate = $StatusPlate

var _defeated := false
var _active_ring: Line2D
var _ring_tween: Tween

var combatant: Combatant

const TRAIL_FRAMES := {
	"attack": [1, 2]
}
signal animation_done()

var _hand_positions: Dictionary = {}
var _hand_rotations: Dictionary = {}
var _flip_h := false

func _ready() -> void:
	weapon_trail.visible = false
	magic_glow.visible = false
	set_target_selectable(false)
	_build_active_ring()
	_layout_status_plate()

func _build_active_ring() -> void:
	var points := PackedVector2Array()
	for i: int in ACTIVE_RING_POINTS:
		var angle := TAU * float(i) / float(ACTIVE_RING_POINTS)
		points.append(Vector2(cos(angle), sin(angle)) * ACTIVE_RING_RADIUS)
	_active_ring = Line2D.new()
	_active_ring.points = points
	_active_ring.closed = true
	_active_ring.width = 2.0
	_active_ring.default_color = ACTIVE_RING_COLOR
	_active_ring.position = ACTIVE_RING_CENTER
	_active_ring.visible = false
	visual_root.add_child(_active_ring)
	visual_root.move_child(_active_ring, 1) # above floor (0), below sprite

func _layout_status_plate() -> void:
	status_plate.scale = Vactor2.ONE / SCALE
	status_plate.position = (Vector2(-status_plate.custom_minimum_size.x * 0.5, STATUS_PLATE_GAP) / SCALE)

func set_frames(frames: SpriteFrames) -> void:
	sprite.sprite_frames = frames
	sprite.play("idle")

func apply_visual(combatant_in: Combatant, flip_h := false) -> void:
	combatant = combatant_in
	status_plate.combatant = combatant
	sprite.sprite_frames = combatant.battle_visual
	scale = SCALE
	sprite.offset.y = -combatant.battle_height
	sprite.offset.x = -combatant.battle_x_offset
	target_hitbox.size.y = combatant.battle_height
	target_hitbox.size.x = combatant.battle_x_offset
	target_hitbox.position.y = -combatant.battle_height
	target_hitbox.position.x = -(combatant.battle_x_offset / 2.0)
	sprite.flip_h = flip_h
	sprite.play("idle")
	_flip_h = flip_h
	_hand_positions = combatant.hand_positions
	_hand_rotations = combatant.hand_rotations
	weapon_anchor.scale.x = -1.0 if flip_h else 1.0
	_update_weapon_anchor()

func refresh_status() -> void:
	status_plate.refresh()

func set_active(value: bool) -> void:
	if value and _defeated:
		return
	_active_ring.visible = value
	status_plate.set_active(value)
	if _ring_tween != null:
		_ring_tween.kill()
		_ring_tween = null
	_active_ring.modulate.a = 1.0
	if value:
		_ring_tween = create_tween().set_loops()
		_ring_tween.tween_property(_active_ring, "modulate:a", 0.45, 0.6)
		_ring_tween.tween_property(_active_ring, "modulate:a", 1.0, 0.6)

func set_defeated() -> void:
	_defeated = true
	set_active(false)
	set_target_selectable(false)
	play_death()
	visual_root.modulate = DEFEATED_MODULATE
	effects_container.visible = false
	status_plate.set_defeated()

func set_effects(effects: Array[EffectView]) -> void:
	_clear_effect_icons()
	for effect_view: EffectView in effects:
		if effect_view == null:
			continue
		if effect_view.image == null:
			continue
		var icon := _create_effect_icon(effect_view)
		effects_container.add_child(icon)

func _clear_effect_icons() -> void:
	for child: Node in effects_container.get_children():
		child.free()

func _create_effect_icon(effect_view: EffectView) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = EFFECT_ICON_SIZE
	icon.texture = effect_view.image
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	icon.tooltip_text = effect_view.tooltip_text
	return icon

func equip_weapon(weapon_texture: Texture2D, offset: Vector2, tip_offset: Vector2 = Vector2(0, -16)) -> void:
	if weapon_texture == null or _hand_positions.is_empty():
		weapon_sprite.visible = false
		return
	weapon_sprite.texture = weapon_texture
	weapon_sprite.offset = offset
	weapon_sprite.visible = true
	tip_point.position = tip_offset
	weapon_trail.set_tip_offset(tip_point)
	magic_glow.set_tip_point(tip_point)
	_update_weapon_anchor()

func configure_vfx(hero_class: Hero.HeroClass) -> void:
	match hero_class:
		Hero.HeroClass.KNIGHT:
			magic_glow.visible = false
			weapon_trail.visible = true
			weapon_trail.trail_color = Color(1.0, 0.95, 0.6)
			weapon_trail.trail_width = 4.0
			weapon_trail.max_points = 10
		Hero.HeroClass.ASSASSIN:
			magic_glow.visible = false
			weapon_trail.visible = true
			weapon_trail.trail_color = Color(0.7, 0.1, 0.9)
			weapon_trail.trail_width = 2.0
			weapon_trail.max_points = 5
		Hero.HeroClass.PRINCESS:
			weapon_trail.visible = false
			magic_glow.visible = true
			magic_glow.glow_color = Color(0.4, 0.8, 1.0)
		_:
			weapon_trail.visible = false
			magic_glow.visible = false

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

func _on_frame_changed() -> void:
	_update_weapon_anchor()
	_update_vfx()

func _update_vfx() -> void:
	var anim := sprite.animation
	var frame := sprite.frame
	
	if TRAIL_FRAMES.has(anim) and frame in TRAIL_FRAMES[anim]:
		if not weapon_trail.is_processing():
			weapon_trail.activate()
	else:
		if weapon_trail.is_processing():
			weapon_trail.deactivate()
	
	if magic_glow.visible:
		if anim == "attack" and not magic_glow.is_processing():
			magic_glow.activate()
		elif anim != "attack" and magic_glow.is_processing():
			magic_glow.deactivate()

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
	if _hand_rotations.has(anim):
		var rotations: Array = _hand_rotations[anim]
		if frame < rotations.size():
			weapon_anchor.rotation = rotations[frame]
		else:
			weapon_anchor.rotation = 0.0
	else:
		weapon_anchor.rotation = 0.0

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation != "idle" and sprite.animation != "death":
		sprite.play("idle")
	emit_signal("animation_done")

func set_target_selectable(selectable: bool) -> void:
	target_hitbox.visible = selectable
	target_hitbox.focus_mode = Control.FOCUS_ALL if selectable else Control.FOCUS_NONE
	set_highlighted(false)

func set_highlighted(value: bool) -> void:
	sprite.modulate = Color(1.25, 1.25, 1.0) if value else Color.WHITE

func _on_target_hitbox_pressed() -> void:
	target_selected.emit(combatant)

func _on_target_hitbox_focus_entered() -> void:
	set_highlighted(true)

func _on_target_hitbox_focus_exited() -> void:
	set_highlighted(false)

func _on_target_hitbox_mouse_entered() -> void:
	set_highlighted(true)

func _on_target_hitbox_mouse_exited() -> void:
	set_highlighted(false)
