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

var _tween: Tween

func activate() -> void:
	if _tween:
		_tween.kill()
	line.width = trail_width
	line.modulate.a = 1.0
	_points.clear()
	line.clear_points()
	set_process(true)
	print("WeaponTrail: Activate")

func deactivate() -> void:
	_tween = create_tween()
	_tween.tween_property(line, "modulate:a", 0.0, 0.1)
	_tween.tween_callback(func():
		line.clear_points()
		set_process(false)
		print("WeaponTrail: Deactivate")
	)

func _process(_delta: float) -> void:
	var global_tip := global_position + _tip_offset.rotated(global_rotation)
	_points.push_front(to_local(global_tip))
	if _points.size() > max_points:
		_points.pop_back()
	line.clear_points()
	for p in _points:
		line.add_point(p)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, 1.0))
	gradient.set_color(1, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	line.gradient = gradient
