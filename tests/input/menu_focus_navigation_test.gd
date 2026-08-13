extends TestCase

var _default_control: Control = null

func run_tests() -> int:
	_begin_test_run()
	var original_mode := InputManager.menu_navigation_mode
	_test_pointer_navigation()
	_test_directional_focus_recovery()
	_test_keyboard_and_controller_directions()
	_test_invalid_defaults_and_dynamic_fallback()
	_test_nested_focus_contexts()
	InputManager.release_menu_focus()
	InputManager._set_menu_navigation_mode(original_mode)
	return _finish_test_run("Menu focus navigation tests")

func _test_pointer_navigation() -> void:
	var root := Control.new()
	var button := Button.new()
	var empty_space := Control.new()
	root.add_child(button)
	root.add_child(empty_space)
	add_child(root)
	_default_control = button
	InputManager.push_menu_focus_context(
		root,
		Callable(self, "_get_default_control")
	)
	InputManager._set_menu_navigation_mode(InputManager.MenuNavigationMode.FOCUS)
	InputManager.restore_menu_focus()

	_expect_true(button.has_focus(), "the test menu starts with visible focus")
	_expect_true(
		not InputManager.handle_pointer_control(empty_space),
		"mouse movement over empty menu space is ignored"
	)
	_expect_true(
		button.has_focus(),
		"empty menu space does not alter existing focus"
	)
	_expect_true(
		InputManager.handle_pointer_control(button),
		"mouse movement over an interactive control enters pointer mode"
	)
	_expect_equal(
		get_viewport().gui_get_focus_owner(),
		null,
		"mouse movement over an interactive control clears focus"
	)

	button.grab_focus()
	InputManager.begin_pointer_control(button)
	_expect_true(
		button.has_focus(),
		"mouse press retains focus until normal button dispatch can complete"
	)
	InputManager._pressed_mouse_buttons[MOUSE_BUTTON_LEFT] = true
	var held_motion := InputEventMouseMotion.new()
	held_motion.relative = Vector2.ONE
	InputManager._input(held_motion)
	_expect_true(
		button.has_focus(),
		"mouse motion during a press does not cancel button activation"
	)
	InputManager._release_menu_focus_after_pointer_click()
	_expect_true(
		button.has_focus(),
		"queued cleanup cannot cancel a later fast mouse press"
	)
	InputManager._pressed_mouse_buttons.clear()
	InputManager.handle_pointer_control(button, true)
	_expect_true(
		button.has_focus(),
		"mouse release schedules focus cleanup after button activation"
	)
	InputManager.release_menu_focus()
	_expect_equal(
		get_viewport().gui_get_focus_owner(),
		null,
		"the deferred post-click release prevents persistent button focus"
	)

	InputManager.pop_menu_focus_context(root)
	root.free()
	_default_control = null

func _test_directional_focus_recovery() -> void:
	var root := Control.new()
	var first := Button.new()
	var second := Button.new()
	root.add_child(first)
	root.add_child(second)
	add_child(root)
	first.focus_neighbor_bottom = first.get_path_to(second)
	second.focus_neighbor_top = second.get_path_to(first)
	_default_control = first
	InputManager.push_menu_focus_context(
		root,
		Callable(self, "_get_default_control")
	)
	InputManager._set_menu_navigation_mode(InputManager.MenuNavigationMode.POINTER)
	InputManager.release_menu_focus()

	var down := _make_action_event(&"ui_down")
	_expect_true(
		InputManager._handle_menu_direction(down),
		"the first direction without focus is consumed"
	)
	_expect_true(first.has_focus(), "the first direction selects the menu default")
	_expect_true(
		not InputManager._handle_menu_direction(down),
		"a second direction is left for Godot focus-neighbor navigation"
	)
	var neighbor := first.find_valid_focus_neighbor(SIDE_BOTTOM)
	_expect_equal(neighbor, second, "the second direction resolves the configured neighbor")
	neighbor.grab_focus()
	_expect_true(second.has_focus(), "normal focus-neighbor navigation can advance")

	InputManager.pop_menu_focus_context(root)
	root.free()
	_default_control = null

func _test_keyboard_and_controller_directions() -> void:
	var root := Control.new()
	var button := Button.new()
	root.add_child(button)
	add_child(root)
	_default_control = button
	InputManager.push_menu_focus_context(
		root,
		Callable(self, "_get_default_control")
	)

	var wasd_event := InputEventKey.new()
	wasd_event.physical_keycode = KEY_W
	wasd_event.pressed = true
	var arrow_event := InputEventKey.new()
	arrow_event.keycode = KEY_DOWN
	arrow_event.pressed = true
	_expect_true(
		InputManager._is_menu_direction_pressed(wasd_event),
		"WASD uses the shared UI direction actions"
	)
	_expect_true(
		InputManager._is_menu_direction_pressed(arrow_event),
		"arrow keys use the shared UI direction actions"
	)

	InputManager._set_menu_navigation_mode(InputManager.MenuNavigationMode.POINTER)
	InputManager.release_menu_focus()
	var dpad_event := InputEventJoypadButton.new()
	dpad_event.button_index = JOY_BUTTON_DPAD_DOWN
	dpad_event.pressed = true
	InputManager._input(dpad_event)
	_expect_true(button.has_focus(), "D-pad navigation restores menu focus")

	InputManager._set_menu_navigation_mode(InputManager.MenuNavigationMode.POINTER)
	InputManager.release_menu_focus()
	var drift_event := InputEventJoypadMotion.new()
	drift_event.axis = JOY_AXIS_LEFT_Y
	drift_event.axis_value = 0.25
	InputManager._input(drift_event)
	_expect_equal(
		get_viewport().gui_get_focus_owner(),
		null,
		"minor stick drift does not restore menu focus"
	)

	var stick_event := InputEventJoypadMotion.new()
	stick_event.axis = JOY_AXIS_LEFT_Y
	stick_event.axis_value = 0.75
	InputManager._input(stick_event)
	_expect_true(button.has_focus(), "analog-stick navigation restores menu focus")

	InputManager.pop_menu_focus_context(root)
	root.free()
	_default_control = null

func _test_invalid_defaults_and_dynamic_fallback() -> void:
	var root := Control.new()
	var disabled_default := Button.new()
	var hidden_default := Button.new()
	var queued_default := Button.new()
	var freed_default := Button.new()
	var fallback := Button.new()
	disabled_default.disabled = true
	hidden_default.hide()
	root.add_child(disabled_default)
	root.add_child(hidden_default)
	root.add_child(queued_default)
	root.add_child(freed_default)
	root.add_child(fallback)
	add_child(root)
	InputManager.push_menu_focus_context(
		root,
		Callable(self, "_get_default_control")
	)
	InputManager._set_menu_navigation_mode(InputManager.MenuNavigationMode.FOCUS)

	_default_control = disabled_default
	InputManager.restore_menu_focus()
	_expect_true(
		queued_default.has_focus() or freed_default.has_focus() or fallback.has_focus(),
		"disabled defaults are skipped"
	)
	InputManager.release_menu_focus()
	_default_control = hidden_default
	InputManager.restore_menu_focus()
	_expect_true(
		queued_default.has_focus() or freed_default.has_focus() or fallback.has_focus(),
		"hidden defaults are skipped"
	)
	InputManager.release_menu_focus()
	queued_default.queue_free()
	_default_control = queued_default
	InputManager.restore_menu_focus()
	_expect_true(freed_default.has_focus(), "queued-for-deletion defaults are skipped")
	InputManager.release_menu_focus()
	freed_default.free()
	_default_control = freed_default
	InputManager.restore_menu_focus()
	_expect_true(fallback.has_focus(), "freed defaults are skipped")
	InputManager.release_menu_focus()
	_default_control = null
	InputManager.restore_menu_focus()
	_expect_true(fallback.has_focus(), "dynamic menus receive a valid tree fallback")

	InputManager.pop_menu_focus_context(root)
	root.free()
	_default_control = null

	var dynamic_root := Control.new()
	add_child(dynamic_root)
	InputManager.push_menu_focus_context(
		dynamic_root,
		Callable(self, "_get_default_control")
	)
	InputManager._set_menu_navigation_mode(InputManager.MenuNavigationMode.POINTER)
	var dynamic_button := Button.new()
	dynamic_root.add_child(dynamic_button)
	_expect_true(
		InputManager._handle_menu_direction(_make_action_event(&"ui_down")),
		"directional input resolves controls added after context registration"
	)
	_expect_true(dynamic_button.has_focus(), "the new dynamic control receives focus")
	InputManager.pop_menu_focus_context(dynamic_root)
	dynamic_root.free()

func _test_nested_focus_contexts() -> void:
	var parent := Control.new()
	var parent_default := Button.new()
	var parent_previous := Button.new()
	parent.add_child(parent_default)
	parent.add_child(parent_previous)
	add_child(parent)
	_default_control = parent_default
	InputManager._set_menu_navigation_mode(InputManager.MenuNavigationMode.FOCUS)
	InputManager.push_menu_focus_context(
		parent,
		Callable(self, "_get_default_control")
	)
	parent_previous.grab_focus()

	var child := Control.new()
	var child_default := Button.new()
	child.add_child(child_default)
	parent.add_child(child)
	InputManager.push_menu_focus_context(
		child,
		Callable(self, "_return_control").bind(child_default)
	)
	InputManager.restore_menu_focus()
	_expect_true(child_default.has_focus(), "a child window owns its focus context")
	InputManager.pop_menu_focus_context(child)
	_expect_true(parent_previous.has_focus(), "closing a child restores parent focus")

	InputManager.handle_pointer_control(parent_previous)
	InputManager.push_menu_focus_context(
		child,
		Callable(self, "_return_control").bind(child_default)
	)
	InputManager.pop_menu_focus_context(child)
	_expect_equal(
		get_viewport().gui_get_focus_owner(),
		null,
		"pointer mode survives modal close without unwanted parent focus"
	)

	InputManager.pop_menu_focus_context(parent)
	parent.free()
	_default_control = null

func _get_default_control() -> Control:
	return _default_control

func _return_control(control: Control) -> Control:
	return control

func _make_action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event
