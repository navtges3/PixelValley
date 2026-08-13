extends Control
class_name GameWindow

signal opened
signal closed

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100

func open() -> void:
	move_to_front()
	show()
	opened.emit()
	InputManager.push_menu_focus_context(
		self,
		Callable(self, "_get_default_focus_target")
	)

func close() -> void:
	hide()
	closed.emit()
	InputManager.pop_menu_focus_context(self)

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
	InputManager.restore_menu_focus()

func _exit_tree() -> void:
	InputManager.pop_menu_focus_context(self)

func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or has_open_child_window():
		return
	if not event.is_echo() and event.is_action_pressed(&"ui_cancel"):
		_handle_cancel()
	get_viewport().set_input_as_handled()
