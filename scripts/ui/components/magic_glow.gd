extends Node2D
class_name MagicGlow

@export var glow_color: Color = Color(0.4, 0.8, 1.0)
@export var pulse_speed: float = 6.0
@export var max_scale: float = 1.6

var _time: float = 0.0
var _tween: Tween
var _glow_sprite: Sprite2D
var _tip_point: Node2D = null

func _ready() -> void:
	_glow_sprite = Sprite2D.new()
	_glow_sprite.texture = _make_glow_texture()
	_glow_sprite.scale = Vector2(0.5, 0.5)
	_glow_sprite.modulate = Color(glow_color.r, glow_color.g, glow_color.b, 0.0)
	_glow_sprite.material = CanvasItemMaterial.new()
	(_glow_sprite.material as CanvasItemMaterial).blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add_child(_glow_sprite)
	set_process(false)

func set_tip_point(tip: Node2D) -> void:
	_tip_point = tip

func activate() -> void:
	if _tween:
		_tween.kill()
	_time = 0.0
	_glow_sprite.modulate.a = 0.0
	set_process(true)
	_tween = create_tween()
	_tween.tween_property(_glow_sprite, "modulate:a", 1.0, 0.2)

func deactivate() -> void:
	_tween = create_tween()
	_tween.tween_property(_glow_sprite, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(func(): set_process(false))

func _process(delta: float) -> void:
	if _tip_point:
		global_position = _tip_point.global_position
	_time += delta
	var pulse := (sin(_time * pulse_speed) + 1.0) / 2.0
	var s = lerp(0.4, max_scale, pulse)
	_glow_sprite.scale = Vector2(s, s)
	var alpha = lerp(0.5, 1.0, pulse)
	_glow_sprite.modulate = Color(glow_color.r, glow_color.g, glow_color.b, alpha)

func _make_glow_texture() -> ImageTexture:
	var size := 24
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	for x in size:
		for y in size:
			var dist := Vector2(x, y).distance_to(center) / (size / 2.0)
			var alpha := clampf(1.0 - dist, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)
