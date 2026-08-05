extends TestCase

const DIALOGUE_WINDOW_SCENE := preload(
	"res://scenes/ui/windows/dialogue_window.tscn"
)

var _advance_count: int = 0
var _cancel_count: int = 0

func run_tests() -> int:
	_begin_test_run()
	_test_long_text_and_response_layout()
	_test_rapid_advance_input()
	_test_cancel_input()
	_test_focus_restoration_and_input_map()
	return _finish_test_run("Dialogue window tests")

func _test_long_text_and_response_layout() -> void:
	var window := _spawn_window()
	var entry := DialogueEntry.new()
	entry.entry_id = &"long_line"
	entry.pages = ["A long dialogue line ".repeat(30)]
	window.show_line(entry, 0)
	_expect_equal(window.dialogue_text.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "long dialogue uses smart word wrapping")
	_expect_true(window.dialogue_text.custom_minimum_size.y >= 48.0, "dialogue reserves readable text height")
	var response := DialogueResponse.new()
	response.text = "A long response option ".repeat(12)
	var options: Array[DialogueResponse] = [response]
	window.show_responses(options)
	var button := window.responses.get_child(0) as Button
	_expect_not_null(button, "response button is created")
	if button != null:
		_expect_equal(button.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "long response text wraps")
		_expect_equal(button.size_flags_horizontal, Control.SIZE_EXPAND_FILL, "response fills the available width")
		_expect_equal(get_viewport().gui_get_focus_owner(), button, "first response receives keyboard and gamepad focus")
	window.free()

func _test_rapid_advance_input() -> void:
	_advance_count = 0
	var window := _spawn_window()
	window.advance_requested.connect(_on_advance_requested)
	var entry := DialogueEntry.new()
	entry.entry_id = &"input_line"
	entry.pages = ["Advance once."]
	window.show_line(entry, 0)
	window._arm_input()
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	window._unhandled_input(event)
	window._unhandled_input(event)
	_expect_equal(_advance_count, 1, "rapid input advances one page per arm cycle")
	window.free()

func _test_cancel_input() -> void:
	_cancel_count = 0
	var window := _spawn_window()
	window._arm_input()
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	window._unhandled_input(event)
	_expect_equal(_cancel_count, 1, "cancel input is routed through the dialogue runner contract")
	window.free()

func _test_focus_restoration_and_input_map() -> void:
	var focus_target := Button.new()
	add_child(focus_target)
	focus_target.grab_focus()
	var window := _spawn_window()
	for cycle: int in 10:
		window.open()
		window.close()
	_expect_equal(get_viewport().gui_get_focus_owner(), focus_target, "repeated open and close restores prior focus")
	var has_keyboard := false
	var has_gamepad := false
	for event: InputEvent in InputMap.action_get_events(&"interact"):
		if event is InputEventKey:
			has_keyboard = true
		elif event is InputEventJoypadButton:
			has_gamepad = true
	_expect_true(has_keyboard, "interact retains a keyboard binding")
	_expect_true(has_gamepad, "interact has a gamepad binding")
	_expect_true(_action_has_gamepad_binding(&"ui_accept"), "response selection has a gamepad binding")
	_expect_true(_action_has_gamepad_binding(&"ui_cancel"), "dialogue cancel has a gamepad binding")
	_expect_true(_action_has_gamepad_binding(&"ui_down"), "response navigation has a gamepad binding")
	window.free()
	focus_target.free()

func _action_has_gamepad_binding(action: StringName) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false

func _spawn_window() -> DialogueWindow:
	var window := DIALOGUE_WINDOW_SCENE.instantiate() as DialogueWindow
	add_child(window)
	window.open()
	window.cancel_requested.connect(_on_cancel_requested)
	return window

func _on_advance_requested() -> void:
	_advance_count += 1

func _on_cancel_requested() -> void:
	_cancel_count += 1
