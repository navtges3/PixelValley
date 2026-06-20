extends RefCounted
class_name HudBarStyle

const COLOR_HP_HIGH := Color(0.25, 0.78, 0.35)
const COLOR_HP_MID := Color(0.9, 0.72, 0.15)
const COLOR_HP_LOW := Color(0.85, 0.22, 0.18)
const COLOR_NRG := Color(0.35, 0.55, 0.9)
const COLOR_XP := Color(0.55, 0.35, 0.85)
const COLOR_BAR_BG := Color(0.12, 0.10, 0.08, 0.8)

static func hp_color(current: int, maximum: int) -> Color:
	if maximum <= 0:
		return COLOR_HP_HIGH
	var ratio := float(current) / float(maximum)
	if ratio > 0.5:
		return COLOR_HP_HIGH
	if ratio > 0.25:
		return COLOR_HP_MID
	return COLOR_HP_LOW

static func apply(bar: ProgressBar, color: Color) -> void:
	var fill := _make_style(color)
	bar.add_theme_stylebox_override("fill", fill)
	var bg := _make_style(COLOR_BAR_BG)
	bar.add_theme_stylebox_override("background", bg)

static func apply_fill(bar: ProgressBar, color: Color) -> void:
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill != null:
		fill = fill.duplicate()
	else:
		fill = _make_style(color)
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)

static func _make_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style
