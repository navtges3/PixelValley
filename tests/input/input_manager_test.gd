extends TestCase

const TEST_DEVICE_ID: int = 99

var _method_change_count: int = 0


func run_tests() -> int:
	_begin_test_run()
	_test_controller_classification()
	_test_input_action_bindings()
	_test_input_method_switching()
	return _finish_test_run("Input manager tests")


func _test_controller_classification() -> void:
	_expect_equal(
		InputManager._classify_controller("Xbox Wireless Controller"),
		InputManager.ControllerFamily.XBOX,
		"Xbox controllers are classified"
	)
	_expect_equal(
		InputManager._classify_controller("Microsoft XInput Controller"),
		InputManager.ControllerFamily.XBOX,
		"XInput controllers are classified"
	)
	_expect_equal(
		InputManager._classify_controller("Sony DualSense Wireless Controller"),
		InputManager.ControllerFamily.PLAYSTATION,
		"PlayStation controllers are classified"
	)
	_expect_equal(
		InputManager._classify_controller("Generic USB Gamepad"),
		InputManager.ControllerFamily.GENERIC,
		"unknown controllers use the generic family"
	)


func _test_input_action_bindings() -> void:
	_expect_true(
		_action_has_key(&"open_hud", KEY_TAB),
		"open_hud retains its keyboard binding"
	)
	_expect_true(
		_action_has_joypad_button(&"open_hud", JOY_BUTTON_START),
		"open_hud has a controller binding"
	)
	_expect_true(
		_action_has_key(&"tab_left", KEY_Q),
		"tab_left has a keyboard binding"
	)
	_expect_true(
		_action_has_joypad_button(
			&"tab_left",
			JOY_BUTTON_LEFT_SHOULDER
		),
		"tab_left has a controller binding"
	)
	_expect_true(
		_action_has_key(&"tab_right", KEY_E),
		"tab_right has a keyboard binding"
	)
	_expect_true(
		_action_has_joypad_button(
			&"tab_right",
			JOY_BUTTON_RIGHT_SHOULDER
		),
		"tab_right has a controller binding"
	)


func _test_input_method_switching() -> void:
	var original_method := InputManager.active_input_method
	var original_device := InputManager.active_controller_device

	InputManager.active_input_method = InputManager.InputMethod.KEYBOARD_MOUSE
	InputManager.active_controller_device = -1
	_method_change_count = 0
	InputManager.input_method_changed.connect(_on_input_method_changed)

	var small_motion := InputEventJoypadMotion.new()
	small_motion.device = TEST_DEVICE_ID
	small_motion.axis_value = 0.25
	InputManager._input(small_motion)

	_expect_equal(
		InputManager.active_input_method,
		InputManager.InputMethod.KEYBOARD_MOUSE,
		"minor stick drift does not activate controller input"
	)

	var controller_motion := InputEventJoypadMotion.new()
	controller_motion.device = TEST_DEVICE_ID
	controller_motion.axis_value = 0.75
	InputManager._input(controller_motion)

	_expect_true(
		InputManager.is_using_controller(),
		"controller motion activates controller input"
	)
	_expect_equal(
		InputManager.active_controller_device,
		TEST_DEVICE_ID,
		"the active controller device is tracked"
	)

	var keyboard_event := InputEventKey.new()
	keyboard_event.physical_keycode = KEY_Q
	keyboard_event.pressed = true
	InputManager._input(keyboard_event)

	_expect_equal(
		InputManager.active_input_method,
		InputManager.InputMethod.KEYBOARD_MOUSE,
		"keyboard input restores keyboard and mouse mode"
	)
	_expect_equal(
		_method_change_count,
		2,
		"input method changes emit once per transition"
	)

	InputManager.input_method_changed.disconnect(_on_input_method_changed)
	InputManager._controller_families.erase(TEST_DEVICE_ID)
	InputManager.active_input_method = original_method
	InputManager.active_controller_device = original_device


func _action_has_key(
	action: StringName,
	physical_keycode: Key
) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if (
			event is InputEventKey
			and event.physical_keycode == physical_keycode
		):
			return true
	return false


func _action_has_joypad_button(
	action: StringName,
	button_index: JoyButton
) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if (
			event is InputEventJoypadButton
			and event.button_index == button_index
		):
			return true
	return false


func _on_input_method_changed(
	_method: InputManager.InputMethod
) -> void:
	_method_change_count += 1
