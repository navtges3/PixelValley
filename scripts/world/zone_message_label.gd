extends Label
class_name ZoneMessageLabel

const DISPLAY_TIME := 2.0
const FADE_TIME    := 0.4
const FLOAT_DIST   := 24.0

var _tween: Tween

func _ready() -> void:
	hide()
	z_index = 10
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)
	add_theme_font_size_override("font_size", 16)

func show_message(msg: String, world_position: Vector2) -> void:
	if _tween:
		_tween.kill()
	text = msg
	global_position = world_position + Vector2(-60, -40)
	modulate.a = 1.0
	show()
	
	_tween = create_tween()
	_tween.tween_property(self, "global_position:y",
			global_position.y - FLOAT_DIST, DISPLAY_TIME).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_interval(DISPLAY_TIME - FADE_TIME)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	_tween.tween_callback(hide)
	
