extends Node

signal prompt_context_changed
signal input_method_changed(method: InputMethod)
signal menu_navigation_mode_changed(mode: MenuNavigationMode)
signal controller_connection_changed(
	device_id: int,
	connected: bool,
	family: ControllerFamily
)

enum InputMethod { KEYBOARD_MOUSE, CONTROLLER, }
enum ControllerFamily { XBOX, PLAYSTATION, GENERIC }
enum MenuNavigationMode { POINTER, FOCUS }

class MenuFocusContext:
	var owner_ref: WeakRef
	var default_focus_resolver: Callable
	var previous_focus_ref: WeakRef

	func _init(
		context_owner: Control,
		resolver: Callable,
		previous_focus: Control
	) -> void:
		owner_ref = weakref(context_owner)
		default_focus_resolver = resolver
		if previous_focus != null:
			previous_focus_ref = weakref(previous_focus)

const JOYPAD_AXIS_THRESHOLD: float = 0.5

var active_input_method: InputMethod = InputMethod.KEYBOARD_MOUSE
var active_controller_device: int = -1
var menu_navigation_mode: MenuNavigationMode = MenuNavigationMode.POINTER

var _controller_families: Dictionary[int, ControllerFamily] = {}
var _menu_focus_contexts: Array[MenuFocusContext] = []
var _pressed_mouse_buttons: Dictionary[MouseButton, bool] = {}
var _pointer_press_should_release_focus: bool = false

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	for device_id: int in Input.get_connected_joypads():
		_register_controller(device_id, false)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		if button_event.pressed:
			_activate_controller(button_event.device)
	elif event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		if absf(motion_event.axis_value) >= JOYPAD_AXIS_THRESHOLD:
			_activate_controller(motion_event.device)
		else:
			return
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			_activate_keyboard_mouse()
	elif event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.pressed:
			_activate_keyboard_mouse()
			_pressed_mouse_buttons[button_event.button_index] = true
			_pointer_press_should_release_focus = (
				_begin_pointer_at_current_position()
			)
			_begin_pointer_at_current_position.call_deferred()
		else:
			_pressed_mouse_buttons.erase(button_event.button_index)
			if _pointer_press_should_release_focus:
				_release_menu_focus_after_pointer_click.call_deferred()
			if _pressed_mouse_buttons.is_empty():
				_pointer_press_should_release_focus = false
		return
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		if motion_event.relative.length_squared() > 0.0:
			_activate_keyboard_mouse()
			if _pressed_mouse_buttons.is_empty():
				_handle_pointer_at_current_position.call_deferred(false)
			else:
				_begin_pointer_at_current_position.call_deferred()
		return

	_handle_menu_direction(event)

func push_menu_focus_context(context_owner: Control, default_focus_resolver: Callable) -> void:
	if not is_instance_valid(context_owner):
		return
	_remove_menu_focus_context(context_owner, false)
	var previous_focus: Control = get_viewport().gui_get_focus_owner()
	_menu_focus_contexts.append(MenuFocusContext.new(
		context_owner,
		default_focus_resolver,
		previous_focus
	))
	if menu_navigation_mode == MenuNavigationMode.FOCUS:
		restore_menu_focus.call_deferred()
	else:
		_release_menu_focus_after_pointer_click.call_deferred()

func pop_menu_focus_context(context_owner: Control) -> void:
	_remove_menu_focus_context(context_owner, true)

func restore_menu_focus() -> bool:
	if menu_navigation_mode != MenuNavigationMode.FOCUS:
		return false
	var context: MenuFocusContext = _get_active_menu_focus_context()
	if context == null:
		return false
	var target := _resolve_default_focus_target(context)
	if not _can_receive_menu_focus(target):
		target = _find_focus_fallback(_get_context_owner(context))
	return focus_menu_control(target)

func focus_menu_control(control: Control) -> bool:
	if menu_navigation_mode != MenuNavigationMode.FOCUS:
		return false
	if not _can_receive_menu_focus(control):
		return false
	var context: MenuFocusContext = _get_active_menu_focus_context()
	if context == null or not _context_contains_control(context, control):
		return false
	control.grab_focus()
	return true

func focus_menu_control_deferred(control: Control) -> void:
	if not is_instance_valid(control):
		return
	_focus_menu_control_from_weak_ref.call_deferred(weakref(control))

func _focus_menu_control_from_weak_ref(control_ref: WeakRef) -> void:
	var control: Control = control_ref.get_ref() as Control
	if is_instance_valid(control):
		focus_menu_control(control)

func release_menu_focus() -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if is_instance_valid(focus_owner):
		focus_owner.release_focus()

func handle_pointer_control(control: Control, release_after_click: bool = false) -> bool:
	var context: MenuFocusContext = _get_active_menu_focus_context()
	if context == null:
		return false
	var interactive := _find_interactive_focus_control(control, context)
	if interactive == null:
		return false
	_set_menu_navigation_mode(MenuNavigationMode.POINTER)
	if release_after_click:
		if not _requires_text_focus(interactive):
			_release_menu_focus_after_pointer_click.call_deferred()
	else:
		release_menu_focus()
	return true

func begin_pointer_control(control: Control) -> bool:
	var context: MenuFocusContext = _get_active_menu_focus_context()
	if context == null:
		return false
	var interactive := _find_interactive_focus_control(control, context)
	if interactive == null:
		return false
	_set_menu_navigation_mode(MenuNavigationMode.POINTER)
	return true

func _handle_menu_direction(event: InputEvent) -> bool:
	if event.is_echo() or not _is_menu_direction_pressed(event):
		return false
	var context: MenuFocusContext = _get_active_menu_focus_context()
	if context == null:
		return false
	_set_menu_navigation_mode(MenuNavigationMode.FOCUS)
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if _can_receive_menu_focus(focus_owner) and _context_contains_control(
		context,
		focus_owner
	):
		return false
	if restore_menu_focus():
		get_viewport().set_input_as_handled()
		return true
	return false

func _is_menu_direction_pressed(event: InputEvent) -> bool:
	return (
		event.is_action_pressed(&"ui_left")
		or event.is_action_pressed(&"ui_right")
		or event.is_action_pressed(&"ui_up")
		or event.is_action_pressed(&"ui_down")
	)

func _handle_pointer_at_current_position(release_after_click: bool) -> void:
	var hovered: Control = get_viewport().gui_get_hovered_control()
	if hovered == null:
		return
	if not release_after_click and not _pressed_mouse_buttons.is_empty():
		begin_pointer_control(hovered)
		return
	handle_pointer_control(hovered, release_after_click)

func _release_menu_focus_after_pointer_click() -> void:
	if not _pressed_mouse_buttons.is_empty():
		return
	release_menu_focus()

func _begin_pointer_at_current_position() -> bool:
	var hovered: Control = get_viewport().gui_get_hovered_control()
	if hovered == null:
		return false
	var context: MenuFocusContext = _get_active_menu_focus_context()
	if context == null:
		return false
	var interactive := _find_interactive_focus_control(hovered, context)
	if interactive == null:
		return false
	_set_menu_navigation_mode(MenuNavigationMode.POINTER)
	return not _requires_text_focus(interactive)

func _set_menu_navigation_mode(mode: MenuNavigationMode) -> void:
	if menu_navigation_mode == mode:
		return
	menu_navigation_mode = mode
	menu_navigation_mode_changed.emit(mode)

func _remove_menu_focus_context(context_owner: Control, restore_parent: bool) -> void:
	var removed_context: MenuFocusContext = null
	for index: int in range(_menu_focus_contexts.size() - 1, -1, -1):
		var context: MenuFocusContext = _menu_focus_contexts[index]
		if _get_context_owner(context) == context_owner:
			removed_context = context
			_menu_focus_contexts.remove_at(index)
			break
	if not restore_parent or removed_context == null:
		return
	if menu_navigation_mode == MenuNavigationMode.POINTER:
		release_menu_focus()
		_release_menu_focus_after_pointer_click.call_deferred()
		return
	_restore_parent_focus(removed_context)

func _restore_parent_focus(removed_context: MenuFocusContext) -> void:
	if menu_navigation_mode != MenuNavigationMode.FOCUS:
		release_menu_focus()
		return
	var parent_context: MenuFocusContext = _get_active_menu_focus_context()
	if parent_context == null:
		return
	var previous: Control = null
	if removed_context.previous_focus_ref != null:
		previous = removed_context.previous_focus_ref.get_ref() as Control
	if (
		_can_receive_menu_focus(previous)
		and _context_contains_control(parent_context, previous)
	):
		previous.grab_focus()
		return
	restore_menu_focus()

func _get_active_menu_focus_context() -> MenuFocusContext:
	_prune_menu_focus_contexts()
	if _menu_focus_contexts.is_empty():
		return null
	return _menu_focus_contexts.back()

func _prune_menu_focus_contexts() -> void:
	for index: int in range(_menu_focus_contexts.size() - 1, -1, -1):
		if _get_context_owner(_menu_focus_contexts[index]) == null:
			_menu_focus_contexts.remove_at(index)

func _get_context_owner(context: MenuFocusContext) -> Control:
	if context == null or context.owner_ref == null:
		return null
	return context.owner_ref.get_ref() as Control

func _resolve_default_focus_target(context: MenuFocusContext) -> Control:
	var resolver: Callable = context.default_focus_resolver
	if not resolver.is_valid():
		return null
	var resolved: Variant = resolver.call()
	if not is_instance_valid(resolved) or not resolved is Control:
		return null
	return resolved as Control

func _find_focus_fallback(root: Control) -> Control:
	if not is_instance_valid(root):
		return null
	if _can_receive_menu_focus(root):
		return root
	for node: Node in root.find_children("*", "Control", true, false):
		var control := node as Control
		if _can_receive_menu_focus(control):
			return control
	return null

func _find_interactive_focus_control(control: Control, context: MenuFocusContext) -> Control:
	var candidate := control
	var root := _get_context_owner(context)
	while candidate != null and (candidate == root or root.is_ancestor_of(candidate)):
		if (
			_can_receive_menu_focus(candidate)
			and candidate.mouse_filter != Control.MOUSE_FILTER_IGNORE
		):
			return candidate
		candidate = candidate.get_parent_control()
	return null

func _context_contains_control(context: MenuFocusContext, control: Control) -> bool:
	var root := _get_context_owner(context)
	return (
		is_instance_valid(root)
		and is_instance_valid(control)
		and (control == root or root.is_ancestor_of(control))
	)

func _can_receive_menu_focus(control: Control) -> bool:
	return (
		is_instance_valid(control)
		and not control.is_queued_for_deletion()
		and control.is_inside_tree()
		and control.is_visible_in_tree()
		and control.focus_mode != Control.FOCUS_NONE
		and not (control is BaseButton and (control as BaseButton).disabled)
	)

func _requires_text_focus(control: Control) -> bool:
	return control is LineEdit or control is TextEdit

func is_using_controller() -> bool:
	return active_input_method == InputMethod.CONTROLLER

func format_action_prompt(action: StringName, verb: String) -> String:
	var binding := get_action_binding_text(action)
	return "Press %s to %s" % [binding, verb]

func get_action_binding_text(action: StringName) -> String:
	var events := InputMap.action_get_events(action)
	if is_using_controller():
		for event: InputEvent in events:
			if event is InputEventJoypadButton:
				var button_event := event as InputEventJoypadButton
				return _get_joypad_button_text(button_event.button_index)
	else:
		for event: InputEvent in events:
			if event is InputEventKey:
				return _get_key_text(event as InputEventKey)
		for event: InputEvent in events:
			if event is InputEventMouseButton:
				var mouse_event := event as InputEventMouseButton
				return _get_mouse_button_text(mouse_event.button_index)
	return String(action).replace("_", " ").capitalize()

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
	var previous_device := active_controller_device
	var was_using_controller := is_using_controller()
	active_controller_device = device_id
	_set_input_method(InputMethod.CONTROLLER)
	if was_using_controller and previous_device != device_id:
		prompt_context_changed.emit()

func _activate_keyboard_mouse() -> void:
	active_controller_device = -1
	_set_input_method(InputMethod.KEYBOARD_MOUSE)

func _set_input_method(method: InputMethod) -> void:
	if active_input_method == method:
		return
	active_input_method = method
	input_method_changed.emit(method)
	prompt_context_changed.emit()

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
			prompt_context_changed.emit()
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

func _get_key_text(event: InputEventKey) -> String:
	var keycode := event.physical_keycode
	if keycode == KEY_NONE:
		keycode = event.keycode
	return OS.get_keycode_string(keycode)

func _get_mouse_button_text(button: MouseButton) -> String:
	match button:
		MOUSE_BUTTON_LEFT:
			return "Left Mouse"
		MOUSE_BUTTON_RIGHT:
			return "Right Mouse"
		MOUSE_BUTTON_MIDDLE:
			return "Middle Mouse"
		_:
			return "Mouse %d" % int(button)

func _get_joypad_button_text(button: JoyButton) -> String:
	var family := get_controller_family()
	match family:
		ControllerFamily.XBOX:
			return _get_xbox_button_text(button)
		ControllerFamily.PLAYSTATION:
			return _get_playstation_button_text(button)
		_:
			return "Button %d" % (int(button) + 1)

func _get_xbox_button_text(button: JoyButton) -> String:
	match button:
		JOY_BUTTON_A:
			return "A"
		JOY_BUTTON_B:
			return "B"
		JOY_BUTTON_X:
			return "X"
		JOY_BUTTON_Y:
			return "Y"
		JOY_BUTTON_LEFT_SHOULDER:
			return "LB"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "RB"
		JOY_BUTTON_BACK:
			return "View"
		JOY_BUTTON_START:
			return "Menu"
		JOY_BUTTON_LEFT_STICK:
			return "L3"
		JOY_BUTTON_RIGHT_STICK:
			return "R3"
		_:
			return "Button %d" % (int(button) + 1)

func _get_playstation_button_text(button: JoyButton) -> String:
	match button:
		JOY_BUTTON_A:
			return "Cross"
		JOY_BUTTON_B:
			return "Circle"
		JOY_BUTTON_X:
			return "Square"
		JOY_BUTTON_Y:
			return "Triangle"
		JOY_BUTTON_LEFT_SHOULDER:
			return "L1"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "R1"
		JOY_BUTTON_BACK:
			return "Create"
		JOY_BUTTON_START:
			return "Options"
		JOY_BUTTON_LEFT_STICK:
			return "L3"
		JOY_BUTTON_RIGHT_STICK:
			return "R3"
		_:
			return "Button %d" % (int(button) + 1)
