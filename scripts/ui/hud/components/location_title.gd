extends Control
class_name LocationTitle

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/Label

var _tween: Tween

func _ready() -> void:
	hide()

func show_location_name(display_name: String) -> void:
	if display_name.is_empty():
		return
	title_label.text = display_name
	if _tween and _tween.is_running():
		_tween.kill()
	show()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	_tween.tween_interval(1.8)
	_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	_tween.tween_callback(hide)
