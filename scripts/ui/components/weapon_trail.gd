extends Node2D
class_name WeaponTrail

@export var max_points: int = 8
@export var trail_color: Color = Color.WHITE
@export var trail_width: float = 3.0

@onready var line: Line2D = $Line2D

var _tip_offset: Vector2 = Vector2(0, -16)
var _points: Array[Vector2] = []

func _ready() -> void:
	line.width = trail_width
	line.default_color = trail_color
	set_process(false)

func set_tip_offset(offset: Vector2) -> void:
	_tip_offset = offset

func activate() -> void:
	_points.clear()
	line.clear_points()
	line.modulate.a = 1.0
	set_process(true)
	print("WeaponTrail: Activating")

func deactivate() -> void:
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func():
		line.clear_points()
		set_process(false)
		print("WeaponTrail: Deactivating"))

func _process(_delta: float) -> void:
	_points.push_front(_tip_offset)
	if _points.size() > max_points:
		_points.pop_back()
	line.clear_points()
	for i in _points.size():
		line.add_point(_points[i])
	var gradient := Gradient.new()
	gradient.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, 1.0))
	gradient.set_color(1, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	line.gradient = gradient
