## Right-hand panel that edits the currently selected DialogueEntry in full:
## entry_id, speaker (with reuse of existing speakers), pages, flow
## (next_entry_id), conditions, actions, and responses.
class_name EntryEditorPanel
extends ScrollContainer

signal changed()

var entry: DialogueEntry
var sequence: DialogueSequence

var _content: VBoxContainer
var _speaker_picker: OptionButton
var _speaker_id_edit: LineEdit
var _speaker_name_edit: LineEdit
var _portrait_preview: TextureRect
var _pages_box: VBoxContainer
var _next_id_field: IDField
var _conditions_box: VBoxContainer
var _actions_box: VBoxContainer
var _responses_box: VBoxContainer
var _portrait_dialog: FileDialog

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

func set_sequence(target_sequence: DialogueSequence) -> void:
	sequence = target_sequence

func edit_entry(target_entry: DialogueEntry) -> void:
	entry = target_entry
	_rebuild()

func clear() -> void:
	entry = null
	for child in get_children():
		child.queue_free()
	var placeholder := Label.new()
	placeholder.text = "Select or add an entry to begin editing."
	add_child(placeholder)

func get_entry_ids() -> Array[String]:
	var ids: Array[String] = []
	if sequence == null:
		return ids
	for e in sequence.entries:
		if e != null and String(e.entry_id) != "":
			ids.append(String(e.entry_id))
	return ids

func refresh_id_options() -> void:
	if entry == null:
		return
	var ids := get_entry_ids()
	if _next_id_field:
		_next_id_field.set_options(ids)
	for child in _responses_box.get_children():
		if child is ResponseEditor:
			child.refresh_id_options()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_content)

	_build_identity_section()
	_build_speaker_section()
	_build_pages_section()
	_build_flow_section()
	_build_conditions_section()
	_build_actions_section()
	_build_responses_section()

func _section_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	_content.add_child(label)
	_content.add_child(HSeparator.new())

func _build_identity_section() -> void:
	_section_label("Entry")

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(row)

	var label := Label.new()
	label.text = "entry_id:"
	row.add_child(label)

	var entry_id_edit := LineEdit.new()
	entry_id_edit.text = String(entry.entry_id)
	entry_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry_id_edit.text_changed.connect(func(t):
		entry.entry_id = StringName(t)
		changed.emit()
	)
	row.add_child(entry_id_edit)

func _build_speaker_section() -> void:
	_section_label("Speaker")

	if entry.speaker == null:
		entry.speaker = DialogueSpeaker.new()

	var picker_row := HBoxContainer.new()
	picker_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(picker_row)

	var picker_label := Label.new()
	picker_label.text = "Reuse speaker:"
	picker_row.add_child(picker_label)

	_speaker_picker = OptionButton.new()
	_speaker_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var speakers := _collect_speakers()
	_speaker_picker.add_item("(new speaker)")
	var selected_index := 0
	for i in speakers.size():
		var s: DialogueSpeaker = speakers[i]
		_speaker_picker.add_item("%s (%s)" % [s.display_name, s.speaker_id])
		if entry.speaker == s:
			selected_index = i + 1
	_speaker_picker.selected = selected_index
	_speaker_picker.item_selected.connect(func(index: int):
		if index == 0:
			entry.speaker = DialogueSpeaker.new()
		else:
			entry.speaker = speakers[index - 1]
		_rebuild()
		changed.emit()
	)
	picker_row.add_child(_speaker_picker)

	var id_row := HBoxContainer.new()
	id_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(id_row)
	var id_label := Label.new()
	id_label.text = "speaker_id:"
	id_row.add_child(id_label)
	_speaker_id_edit = LineEdit.new()
	_speaker_id_edit.text = String(entry.speaker.speaker_id)
	_speaker_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speaker_id_edit.text_changed.connect(func(t):
		entry.speaker.speaker_id = StringName(t)
		changed.emit()
	)
	id_row.add_child(_speaker_id_edit)

	var name_row := HBoxContainer.new()
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(name_row)
	var name_label := Label.new()
	name_label.text = "display_name:"
	name_row.add_child(name_label)
	_speaker_name_edit = LineEdit.new()
	_speaker_name_edit.text = entry.speaker.display_name
	_speaker_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speaker_name_edit.text_changed.connect(func(t):
		entry.speaker.display_name = t
		changed.emit()
	)
	name_row.add_child(_speaker_name_edit)

	var portrait_row := HBoxContainer.new()
	portrait_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(portrait_row)

	_portrait_preview = TextureRect.new()
	_portrait_preview.custom_minimum_size = Vector2(48, 48)
	_portrait_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_portrait_preview.texture = entry.speaker.portrait
	portrait_row.add_child(_portrait_preview)

	var portrait_button := Button.new()
	portrait_button.text = "Choose Portrait..."
	portrait_button.pressed.connect(_on_choose_portrait)
	portrait_row.add_child(portrait_button)

	var clear_portrait_button := Button.new()
	clear_portrait_button.text = "Clear"
	clear_portrait_button.pressed.connect(func():
		entry.speaker.portrait = null
		_portrait_preview.texture = null
		changed.emit()
	)
	portrait_row.add_child(clear_portrait_button)

func _collect_speakers() -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	if sequence == null:
		return result
	for e in sequence.entries:
		if e != null and e.speaker != null:
			var key := e.speaker.get_instance_id()
			if not seen.has(key):
				seen[key] = true
				result.append(e.speaker)
	return result

func _on_choose_portrait() -> void:
	if _portrait_dialog == null:
		_portrait_dialog = FileDialog.new()
		_portrait_dialog.access = FileDialog.ACCESS_RESOURCES
		_portrait_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_portrait_dialog.filters = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp,*.svg ; Images"])
		_portrait_dialog.current_dir = "res://"
		_portrait_dialog.size = Vector2i(700, 500)
		_portrait_dialog.file_selected.connect(_on_portrait_selected)
		add_child(_portrait_dialog)
	_portrait_dialog.popup_centered()

func _on_portrait_selected(path: String) -> void:
	var tex := load(path)
	if tex is Texture2D:
		entry.speaker.portrait = tex
		_portrait_preview.texture = tex
		changed.emit()

func _build_pages_section() -> void:
	_section_label("Pages")
	_pages_box = VBoxContainer.new()
	_content.add_child(_pages_box)
	_rebuild_pages()

	var add_page_button := Button.new()
	add_page_button.text = "+ Add Page"
	add_page_button.pressed.connect(func():
		entry.pages.append("")
		_rebuild_pages()
		changed.emit()
	)
	_content.add_child(add_page_button)

func _rebuild_pages() -> void:
	for child in _pages_box.get_children():
		child.queue_free()
	for i in entry.pages.size():
		_pages_box.add_child(_build_page_row(i))

func _build_page_row(index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var text_edit := TextEdit.new()
	text_edit.text = entry.pages[index]
	text_edit.custom_minimum_size = Vector2(0, 50)
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.text_changed.connect(func():
		entry.pages[index] = text_edit.text
		changed.emit()
	)
	row.add_child(text_edit)

	var controls := VBoxContainer.new()
	row.add_child(controls)

	var up_button := Button.new()
	up_button.text = "^"
	up_button.disabled = index == 0
	up_button.pressed.connect(func():
		var tmp := entry.pages[index]
		entry.pages[index] = entry.pages[index - 1]
		entry.pages[index - 1] = tmp
		_rebuild_pages()
		changed.emit()
	)
	controls.add_child(up_button)

	var down_button := Button.new()
	down_button.text = "v"
	down_button.disabled = index == entry.pages.size() - 1
	down_button.pressed.connect(func():
		var tmp2 := entry.pages[index]
		entry.pages[index] = entry.pages[index + 1]
		entry.pages[index + 1] = tmp2
		_rebuild_pages()
		changed.emit()
	)
	controls.add_child(down_button)

	var remove_button := Button.new()
	remove_button.text = "x"
	remove_button.pressed.connect(func():
		entry.pages.remove_at(index)
		_rebuild_pages()
		changed.emit()
	)
	controls.add_child(remove_button)

	return row

func _build_flow_section() -> void:
	_section_label("Flow")

	var next_row := HBoxContainer.new()
	next_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(next_row)
	var next_label := Label.new()
	next_label.text = "next_entry_id:"
	next_row.add_child(next_label)
	_next_id_field = IDField.new()
	_next_id_field.set_value(String(entry.next_entry_id))
	_next_id_field.set_options(get_entry_ids())
	_next_id_field.value_changed.connect(func(v):
		entry.next_entry_id = StringName(v)
		changed.emit()
	)
	next_row.add_child(_next_id_field)

func _build_conditions_section() -> void:
	_section_label("Conditions")
	_conditions_box = VBoxContainer.new()
	_content.add_child(_conditions_box)
	_rebuild_conditions()

	var add_button := Button.new()
	add_button.text = "+ Add Condition"
	add_button.pressed.connect(func():
		entry.conditions.append(DialogueCondition.new())
		_rebuild_conditions()
		changed.emit()
	)
	_content.add_child(add_button)

func _rebuild_conditions() -> void:
	for child in _conditions_box.get_children():
		child.queue_free()
	for cond in entry.conditions:
		var row := ConditionRowEditor.new()
		row.set_condition(cond)
		row.changed.connect(func(): changed.emit())
		row.remove_requested.connect(func():
			entry.conditions.erase(cond)
			_rebuild_conditions()
			changed.emit()
		)
		_conditions_box.add_child(row)

func _build_actions_section() -> void:
	_section_label("Actions")
	_actions_box = VBoxContainer.new()
	_content.add_child(_actions_box)
	_rebuild_actions()

	var add_button := Button.new()
	add_button.text = "+ Add Action"
	add_button.pressed.connect(func():
		entry.actions.append(DialogueAction.new())
		_rebuild_actions()
		changed.emit()
	)
	_content.add_child(add_button)

func _rebuild_actions() -> void:
	for child in _actions_box.get_children():
		child.queue_free()
	for act in entry.actions:
		var row := ActionRowEditor.new()
		row.set_action(act)
		row.changed.connect(func(): changed.emit())
		row.remove_requested.connect(func():
			entry.actions.erase(act)
			_rebuild_actions()
			changed.emit()
		)
		_actions_box.add_child(row)

func _build_responses_section() -> void:
	_section_label("Responses")
	_responses_box = VBoxContainer.new()
	_content.add_child(_responses_box)
	_rebuild_responses()

	var add_button := Button.new()
	add_button.text = "+ Add Response"
	add_button.pressed.connect(func():
		entry.responses.append(DialogueResponse.new())
		_rebuild_responses()
		changed.emit()
	)
	_content.add_child(add_button)

func _rebuild_responses() -> void:
	for child in _responses_box.get_children():
		child.queue_free()
	for resp in entry.responses:
		var row := ResponseEditor.new()
		row.set_response(resp, Callable(self, "get_entry_ids"))
		row.changed.connect(func(): changed.emit())
		row.remove_requested.connect(func():
			entry.responses.erase(resp)
			_rebuild_responses()
			changed.emit()
		)
		_responses_box.add_child(row)
