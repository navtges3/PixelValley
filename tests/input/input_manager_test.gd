extends TestCase

const TEST_DEVICE_ID: int = 99
const SECOND_TEST_DEVICE_ID: int = 100
const PLAYER_SCENE := preload(
	"res://scenes/world/characters/player.tscn"
)
const INTERACT_AREA_SCENE := preload(
	"res://scenes/world/interact_area.tscn"
)

var _method_change_count: int = 0
var _prompt_context_change_count: int = 0


func run_tests() -> int:
	_begin_test_run()
	_test_controller_classification()
	_test_input_action_bindings()
	_test_action_prompt_formatting()
	_test_prompt_context_switching()
	_test_visible_interaction_prompt_refresh()
	_test_interaction_prompt_cleanup_and_ownership()
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


func _test_action_prompt_formatting() -> void:
	var original_method := InputManager.active_input_method
	var original_device := InputManager.active_controller_device

	InputManager.active_input_method = InputManager.InputMethod.KEYBOARD_MOUSE
	InputManager.active_controller_device = -1
	_expect_equal(
		InputManager.get_action_binding_text(&"interact"),
		"F",
		"keyboard interaction prompts use F"
	)
	_expect_equal(
		InputManager.format_action_prompt(&"interact", "Talk"),
		"Press F to Talk",
		"keyboard actions format complete prompts"
	)

	InputManager.active_input_method = InputManager.InputMethod.CONTROLLER
	InputManager.active_controller_device = TEST_DEVICE_ID
	InputManager._controller_families[TEST_DEVICE_ID] = (
		InputManager.ControllerFamily.XBOX
	)
	_expect_equal(
		InputManager.get_action_binding_text(&"interact"),
		"A",
		"Xbox interaction prompts use A"
	)

	InputManager._controller_families[TEST_DEVICE_ID] = (
		InputManager.ControllerFamily.PLAYSTATION
	)
	_expect_equal(
		InputManager.get_action_binding_text(&"interact"),
		"Cross",
		"PlayStation interaction prompts use Cross"
	)

	InputManager._controller_families[TEST_DEVICE_ID] = (
		InputManager.ControllerFamily.GENERIC
	)
	_expect_equal(
		InputManager.get_action_binding_text(&"interact"),
		"Button 1",
		"generic interaction prompts use a numbered button"
	)

	InputManager._controller_families.erase(TEST_DEVICE_ID)
	InputManager.active_input_method = original_method
	InputManager.active_controller_device = original_device


func _test_prompt_context_switching() -> void:
	var original_method := InputManager.active_input_method
	var original_device := InputManager.active_controller_device

	InputManager.active_input_method = InputManager.InputMethod.KEYBOARD_MOUSE
	InputManager.active_controller_device = -1
	InputManager._controller_families[TEST_DEVICE_ID] = (
		InputManager.ControllerFamily.XBOX
	)
	InputManager._controller_families[SECOND_TEST_DEVICE_ID] = (
		InputManager.ControllerFamily.PLAYSTATION
	)
	_prompt_context_change_count = 0
	InputManager.prompt_context_changed.connect(
		_on_prompt_context_changed
	)

	InputManager._activate_controller(TEST_DEVICE_ID)
	InputManager._activate_controller(SECOND_TEST_DEVICE_ID)
	InputManager._activate_controller(SECOND_TEST_DEVICE_ID)
	InputManager._activate_keyboard_mouse()

	_expect_equal(
		_prompt_context_change_count,
		3,
		"prompt context changes once per method or controller transition"
	)

	InputManager.prompt_context_changed.disconnect(
		_on_prompt_context_changed
	)
	InputManager._controller_families.erase(TEST_DEVICE_ID)
	InputManager._controller_families.erase(SECOND_TEST_DEVICE_ID)
	InputManager.active_input_method = original_method
	InputManager.active_controller_device = original_device


func _test_visible_interaction_prompt_refresh() -> void:
	var original_method := InputManager.active_input_method
	var original_device := InputManager.active_controller_device

	InputManager.active_input_method = InputManager.InputMethod.KEYBOARD_MOUSE
	InputManager.active_controller_device = -1

	var player := PLAYER_SCENE.instantiate() as Player
	var camera := player.get_node("Camera2D") as Camera2D
	camera.free()
	var interact_area := INTERACT_AREA_SCENE.instantiate() as InteractArea
	add_child(player)
	add_child(interact_area)
	interact_area.prompt_label = "Talk"
	interact_area._on_body_entered(player)
	_expect_equal(
		player.prompt_label.text,
		"Press F to Talk",
		"visible interaction prompts start with the keyboard binding"
	)

	InputManager._controller_families[TEST_DEVICE_ID] = (
		InputManager.ControllerFamily.XBOX
	)
	InputManager.active_input_method = InputManager.InputMethod.CONTROLLER
	InputManager.active_controller_device = TEST_DEVICE_ID
	InputManager.prompt_context_changed.emit()
	_expect_equal(
		player.prompt_label.text,
		"Press A to Talk",
		"visible interaction prompts refresh without area re-entry"
	)

	interact_area._on_body_exited(player)
	_expect_true(
		not player.prompt_label.visible,
		"the refreshed interaction prompt clears on area exit"
	)

	interact_area.free()
	player.free()
	InputManager._controller_families.erase(TEST_DEVICE_ID)
	InputManager.active_input_method = original_method
	InputManager.active_controller_device = original_device


func _test_interaction_prompt_cleanup_and_ownership() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	var camera := player.get_node("Camera2D") as Camera2D
	camera.free()
	var first_area := INTERACT_AREA_SCENE.instantiate() as InteractArea
	var second_area := INTERACT_AREA_SCENE.instantiate() as InteractArea
	first_area.prompt_label = "Collect Wood Bundle"
	second_area.prompt_label = "Collect Wood Bundle"
	add_child(player)
	add_child(first_area)
	add_child(second_area)

	first_area._on_body_entered(player)
	second_area._on_body_entered(player)
	first_area._on_body_exited(player)
	_expect_true(
		player.prompt_label.visible,
		"one interaction area cannot clear another area's matching prompt"
	)
	_expect_equal(
		player.prompt_label.text,
		InputManager.format_action_prompt(&"interact", "Collect Wood Bundle"),
		"the active interaction area retains its authored prompt"
	)

	second_area.hide()
	_expect_true(
		not player.prompt_label.visible,
		"hiding an interaction area clears its owned prompt"
	)
	second_area.show()
	second_area._on_body_entered(player)
	second_area.set_enabled(false)
	_expect_true(
		not player.prompt_label.visible,
		"disabling an interaction area clears its owned prompt"
	)

	first_area._on_body_entered(player)
	remove_child(first_area)
	_expect_true(
		not player.prompt_label.visible,
		"removing an interaction area clears its owned prompt"
	)

	first_area.free()
	second_area.free()
	player.free()


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


func _on_prompt_context_changed() -> void:
	_prompt_context_change_count += 1
