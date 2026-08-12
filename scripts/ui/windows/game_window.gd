extends Control
class_name GameWindow

signal opened
signal closed

var _previous_focus: Control = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100

func open() -> void:
	_capture_previous_focus()
	move_to_front()
	show()
	opened.emit()
	_apply_default_focus.call_deferred()

func close() -> void:
	hide()
	closed.emit()
	_restore_previous_focus.call_deferred()

func has_open_child_window() -> bool:
	for child: Node in get_children():
		if child is GameWindow and (child as GameWindow).is_open():
			return true
	return false

func is_open() -> bool:
	return is_visible_in_tree()

func _get_default_focus_target() -> Control:
	return null

func _handle_cancel() -> void:
	close()

func _apply_default_focus() -> void:
	var target: Control = _get_default_focus_target()
	if _can_receive_focus(target):
		target.grab_focus()

func _capture_previous_focus() -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if focus_owner != null and not is_ancestor_of(focus_owner):
		_previous_focus = focus_owner
	else:
		_previous_focus = null

func _restore_previous_focus() -> void:
	if _can_receive_focus(_previous_focus):
		_previous_focus.grab_focus()
	_previous_focus = null

func _can_receive_focus(control: Control) -> bool:
	if not is_instance_valid(control):
		return false
	if not control.is_visible_in_tree():
		return false
	if control.focus_mode == Control.FOCUS_NONE:
		return false
	if control is BaseButton and (control as BaseButton).disabled:
		return false
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or has_open_child_window():
		return
	if not event.is_echo() and event.is_action_pressed(&"ui_cancel"):
		_handle_cancel()
	get_viewport().set_input_as_handled()
