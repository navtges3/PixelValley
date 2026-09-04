## Left-hand panel listing every DialogueEntry in the currently loaded
## sequence. Handles selecting, adding, duplicating, and deleting entries.
class_name EntryListPanel
extends VBoxContainer

signal entry_selected(entry: DialogueEntry)
signal entries_changed()

var sequence: DialogueSequence
var _list_box: VBoxContainer
var _selected_entry: DialogueEntry
var _entry_buttons: Dictionary = {}  # DialogueEntry -> Button

func _init() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL

func set_sequence(target_sequence: DialogueSequence) -> void:
	sequence = target_sequence
	_selected_entry = null
	_rebuild()

func refresh() -> void:
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_entry_buttons.clear()

	var header := Label.new()
	header.text = "Entries"
	header.add_theme_font_size_override("font_size", 16)
	add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_box)

	if sequence != null:
		for entry in sequence.entries:
			_list_box.add_child(_build_entry_row(entry))

	var add_button := Button.new()
	add_button.text = "+ Add Entry"
	add_button.pressed.connect(_on_add_entry)
	add_child(add_button)

func _build_entry_row(entry: DialogueEntry) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var select_button := Button.new()
	var id_text := String(entry.entry_id) if String(entry.entry_id) != "" else "(unnamed)"
	var speaker_text := ""
	if entry.speaker != null and entry.speaker.display_name != "":
		speaker_text = " — %s" % entry.speaker.display_name
	select_button.text = id_text + speaker_text
	select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_button.toggle_mode = true
	select_button.button_pressed = entry == _selected_entry
	select_button.pressed.connect(func():
		_selected_entry = entry
		_update_button_styles()
		entry_selected.emit(entry)
	)
	row.add_child(select_button)
	_entry_buttons[entry] = select_button

	var duplicate_button := Button.new()
	duplicate_button.text = "Dup"
	duplicate_button.tooltip_text = "Duplicate this entry"
	duplicate_button.pressed.connect(func(): _duplicate_entry(entry))
	row.add_child(duplicate_button)

	var delete_button := Button.new()
	delete_button.text = "Del"
	delete_button.tooltip_text = "Delete this entry"
	delete_button.pressed.connect(func(): _delete_entry(entry))
	row.add_child(delete_button)

	return row

func _update_button_styles() -> void:
	for entry in _entry_buttons.keys():
		var button: Button = _entry_buttons[entry]
		button.button_pressed = entry == _selected_entry

func _on_add_entry() -> void:
	if sequence == null:
		return
	var new_entry := DialogueEntry.new()
	new_entry.entry_id = StringName(_next_default_id())
	new_entry.pages.append("")
	sequence.entries.append(new_entry)
	_rebuild()
	_selected_entry = new_entry
	_update_button_styles()
	entry_selected.emit(new_entry)
	entries_changed.emit()

func _next_default_id() -> String:
	var index := 1
	var existing: Dictionary = {}
	for entry in sequence.entries:
		existing[String(entry.entry_id)] = true
	while existing.has("new_entry_%d" % index):
		index += 1
	return "new_entry_%d" % index

func _duplicate_entry(entry: DialogueEntry) -> void:
	var copy := entry.duplicate(true) as DialogueEntry
	copy.entry_id = StringName(String(entry.entry_id) + "_copy")
	var index := sequence.entries.find(entry)
	sequence.entries.insert(index + 1, copy)
	_rebuild()
	entries_changed.emit()

func _delete_entry(entry: DialogueEntry) -> void:
	sequence.entries.erase(entry)
	if _selected_entry == entry:
		_selected_entry = null
	_rebuild()
	entries_changed.emit()
	if _selected_entry == null:
		entry_selected.emit(null)
