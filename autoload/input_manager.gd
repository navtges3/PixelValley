extends Node

signal input_method_changed(method: InputMethod)
signal controller_connection_changed(
	device_id: int,
	connected: bool,
	family: ControllerFamily
)

enum InputMethod { KEYBOARD_MOUSE, CONTROLLER, }
enum ControllerFamily { XBOX, PLAYSTATION, GENERIC }

const JOYPAD_AXIS_THRESHOLD: float = 0.5

var active_input_method: InputMethod = InputMethod.KEYBOARD_MOUSE
var active_controller_device: int = -1

var _controller_families: Dictionary[int, ControllerFamily] = {}

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	for device_id: int in Input.get_connected_joypads():
		_register_controller(device_id, false)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		if button_event.pressed:
			_activate_controller(button_event.device)
		return
	if event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		if absf(motion_event.axis_value) >= JOYPAD_AXIS_THRESHOLD:
			_activate_controller(motion_event.device)
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			_activate_keyboard_mouse()
		return
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.pressed:
			_activate_keyboard_mouse()
		return
	if event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		if motion_event.relative.length_squared() > 0.0:
			_activate_keyboard_mouse()

func is_using_controller() -> bool:
	return active_input_method == InputMethod.CONTROLLER

func get_connected_controller_ids() -> Array[int]:
	var device_ids: Array[int] = []
	for device_id: int in _controller_families:
		device_ids.append(device_id)
	return device_ids

func get_controller_family(device_id: int = -1) -> ControllerFamily:
	var resolved_device_id := device_id
	if resolved_device_id < 0:
		resolved_device_id = active_controller_device
	if not _controller_families.has(resolved_device_id):
		return ControllerFamily.GENERIC
	return _controller_families[resolved_device_id]

func _activate_controller(device_id: int) -> void:
	if not _controller_families.has(device_id):
		_register_controller(device_id, false)
	active_controller_device = device_id
	_set_input_method(InputMethod.CONTROLLER)

func _activate_keyboard_mouse() -> void:
	active_controller_device = -1
	_set_input_method(InputMethod.KEYBOARD_MOUSE)

func _set_input_method(method: InputMethod) -> void:
	if active_input_method == method:
		return
	active_input_method = method
	input_method_changed.emit(method)

func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		_register_controller(device_id)
		return
	var family := ControllerFamily.GENERIC
	if _controller_families.has(device_id):
		family = _controller_families[device_id]
	_controller_families.erase(device_id)
	if active_controller_device == device_id:
		var remaining_devices := get_connected_controller_ids()
		if _controller_families.is_empty():
			active_controller_device = -1
			_set_input_method(InputMethod.KEYBOARD_MOUSE)
		else:
			active_controller_device = remaining_devices[0]
	controller_connection_changed.emit(device_id, false, family)

func _register_controller(device_id: int, emit_connection_signal: bool = true) -> void:
	var controller_name := Input.get_joy_name(device_id)
	var family := _classify_controller(controller_name)
	_controller_families[device_id] = family
	if emit_connection_signal:
		controller_connection_changed.emit(device_id, true, family)

func _classify_controller(controller_name: String) -> ControllerFamily:
	var normalized_name := controller_name.to_lower()
	if (
		"xbox" in normalized_name or
		"xinput" in normalized_name or
		"microsoft" in normalized_name
	):
		return ControllerFamily.XBOX
	if (
		"playstation" in normalized_name or
		"dualshock" in normalized_name or
		"dualsense" in normalized_name or
		"sony" in normalized_name or
		normalized_name.begins_with("ps")
	):
		return ControllerFamily.PLAYSTATION
	return ControllerFamily.GENERIC
