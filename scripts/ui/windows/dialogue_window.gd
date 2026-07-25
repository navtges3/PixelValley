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

func show_line(entry: DialogueEntry, page_index: int) -> void:
	_clear_responses()
	var has_speaker: bool = entry.speaker != null
	speaker_name.visible = has_speaker
	portrait.visible = has_speaker and entry.speaker.portrait != null
	if has_speaker:
		speaker_name.text = entry.speaker.display_name
		portrait.texture = entry.speaker.portrait
	dialogue_text.text = entry.pages[page_index]
	advance_hint.visible = true

func show_responses(options: Array[DialogueResponse]) -> void:
	_clear_responses()
	advance_hint.visible = false
	for index: int in options.size():
		var button := Button.new()
		button.text = options[index].text
		button.pressed.connect(response_requested.emit.bind(index))
		responses.add_child(button)
	var first_button := responses.get_child(0) as Button
	first_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("ui_cancel"):
		cancel_requested.emit()
		get_viewport().set_input_as_handled()
	elif (responses.get_child_count() == 0 and
		(event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"))):
		advance_requested.emit()
		get_viewport().set_input_as_handled()

func _clear_responses() -> void:
	for child: Node in responses.get_children():
		responses.remove_child(child)
		child.queue_free()
