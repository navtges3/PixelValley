extends GameWindow
class_name DialogueWindow

signal advance_requested
signal response_requested(index: int)
signal cancel_requested

@onready var portrait: TextureRect = %Portrait
@onready var speaker_name: Label = %SpeakerName
@onready var dialogue_text: Label = %DialogueText
@onready var responses: VBoxContainer = %Responses
@onready var advance_hint: Label = %AdvanceHint

var _input_armed: bool = false

func _ready() -> void:
	super._ready()
	InputManager.prompt_context_changed.connect(_on_prompt_context_changed)
	_refresh_advance_hint()

func open() -> void:
	_input_armed = false
	super.open()

func close() -> void:
	_input_armed = false
	super.close()

func show_line(entry: DialogueEntry, page_index: int) -> void:
	_input_armed = false
	_clear_responses()
	var has_speaker: bool = entry.speaker != null
	speaker_name.visible = has_speaker
	portrait.visible = has_speaker and entry.speaker.portrait != null
	if has_speaker:
		speaker_name.text = entry.speaker.display_name
		portrait.texture = entry.speaker.portrait
	dialogue_text.text = entry.pages[page_index]
	_refresh_advance_hint()
	advance_hint.visible = true
	call_deferred("_arm_input")

func show_responses(options: Array[DialogueResponse]) -> void:
	_input_armed = false
	_clear_responses()
	advance_hint.visible = false
	for index: int in options.size():
		var button := Button.new()
		button.text = options[index].text
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(response_requested.emit.bind(index))
		responses.add_child(button)
	InputManager.restore_menu_focus()
	InputManager.restore_menu_focus.call_deferred()
	call_deferred("_arm_input")

func _get_default_focus_target() -> Control:
	for child: Node in responses.get_children():
		if child is Button and not (child as Button).disabled:
			return child as Button
	return null

func _arm_input() -> void:
	if is_open():
		_input_armed = true

func _clear_responses() -> void:
	for child: Node in responses.get_children():
		responses.remove_child(child)
		child.queue_free()

func _on_prompt_context_changed() -> void:
	if is_open() and advance_hint.visible:
		_refresh_advance_hint()

func _refresh_advance_hint() -> void:
	advance_hint.text = InputManager.format_action_prompt(&"interact", "Continue") + "..."

func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not _input_armed or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		cancel_requested.emit()
		get_viewport().set_input_as_handled()
	elif (responses.get_child_count() == 0 and
		(event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"))):
		_input_armed = false
		advance_requested.emit()
		get_viewport().set_input_as_handled()
