extends Control
class_name AcquisitionNotification

signal notification_started(entry: RewardEntry)
signal notification_finished(entry: RewardEntry)

@export_range(0.1, 10.0) var display_seconds: float = 2.0

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/MarginContainer/Label
@onready var display_timer: Timer = $DisplayTimer

var _queue: Array[RewardEntry] = []
var _active_entry: RewardEntry = null

func _ready() -> void:
	pass

func clear() -> void:
	display_timer.stop()
	_queue.clear()
	_active_entry = null
	panel.hide()

func enqueue(rewards: Array[RewardEntry]) -> void:
	for entry: RewardEntry in rewards:
		if entry != null:
			_queue.append(entry)
	_show_next()

func _on_display_timer_timeout() -> void:
	var finished_entry := _active_entry
	_active_entry = null
	panel.hide()
	notification_finished.emit(finished_entry)
	_show_next()

func _show_next() -> void:
	if _active_entry != null or _queue.is_empty():
		return
	_active_entry = _queue.pop_front()
	label.text = _active_entry.display_text
	label.add_theme_color_override("font_color", _active_entry.color)
	panel.show()
	notification_started.emit(_active_entry)
	display_timer.start(display_seconds)
