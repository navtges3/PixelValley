extends Node2D
class_name WeaponTrail

@export var max_points: int = 8
@export var trail_color: Color = Color.WHITE
@export var trail_width: float = 3.0

@onready var line: Line2D = $Line2D

var _tip_point: Node2D = null
var _points: Array[Vector2] = []

func _ready() -> void:
	line.width = trail_width
	line.default_color = trail_color
	set_process(false)

func set_tip_offset(tip: Node2D) -> void:
	_tip_point = tip

var _tween: Tween

func activate() -> void:
	if _tween:
		_tween.kill()
	line.width = trail_width
	line.modulate.a = 1.0
	_points.clear()
	line.clear_points()
	set_process(true)

func deactivate() -> void:
	_tween = create_tween()
	_tween.tween_property(line, "modulate:a", 0.0, 0.1)
	_tween.tween_callback(func():
		line.clear_points()
		set_process(false))

func _process(_delta: float) -> void:
	if _tip_point == null:
		return
	_points.push_front(to_local(_tip_point.global_position))
	if _points.size() > max_points:
		_points.pop_back()
	line.clear_points()
	for p in _points:
		line.add_point(p)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, 1.0))
	gradient.set_color(1, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	line.gradient = gradient
	line.width = trail_width
