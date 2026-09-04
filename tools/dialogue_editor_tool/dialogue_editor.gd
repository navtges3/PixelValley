## Root controller for the standalone Dialogue Editor tool.
## Run this scene directly (F6) from inside the Godot editor. It can open
## any DialogueSequence .tres resource in the project, edit it with a
## purpose-built UI, and save it back.
extends Control

var current_sequence: DialogueSequence
var current_path: String = ""
var _dirty: bool = false
var _refreshing_fields: bool = false

var entry_list: EntryListPanel
var entry_editor: EntryEditorPanel
var validation_list: ItemList
var path_label: Label
var sequence_id_edit: LineEdit
var quest_id_spin: SpinBox
var priority_spin: SpinBox
var start_id_field: IDField
var can_cancel_check: CheckBox
var state_entries_box: VBoxContainer
var open_dialog: FileDialog
var save_dialog: FileDialog
var _state_entry_keys: Array[StringName] = []
var _state_entry_targets: Array[StringName] = []
var _state_target_fields: Array[IDField] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_new_sequence()

func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_vbox)

	root_vbox.add_child(_build_top_bar())

	var split := HSplitContainer.new()
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 380
	root_vbox.add_child(split)

	var left_panel := VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(340, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(left_panel)

	left_panel.add_child(_build_sequence_fields())

	entry_list = EntryListPanel.new()
	entry_list.entry_selected.connect(_on_entry_selected)
	entry_list.entries_changed.connect(_on_entries_changed)
	left_panel.add_child(entry_list)

	entry_editor = EntryEditorPanel.new()
	entry_editor.changed.connect(_on_entry_editor_changed)
	split.add_child(entry_editor)

	var validation_panel := VBoxContainer.new()
	validation_panel.custom_minimum_size = Vector2(0, 130)
	root_vbox.add_child(validation_panel)

	var validation_header := Label.new()
	validation_header.text = "Validation"
	validation_panel.add_child(validation_header)

	validation_list = ItemList.new()
	validation_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	validation_list.custom_minimum_size = Vector2(0, 100)
	validation_panel.add_child(validation_list)

func _build_top_bar() -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var new_button := Button.new()
	new_button.text = "New"
	new_button.pressed.connect(_new_sequence)
	bar.add_child(new_button)

	var open_button := Button.new()
	open_button.text = "Open..."
	open_button.pressed.connect(func(): open_dialog.popup_centered())
	bar.add_child(open_button)

	var save_button := Button.new()
	save_button.text = "Save"
	save_button.pressed.connect(_on_save_pressed)
	bar.add_child(save_button)

	var save_as_button := Button.new()
	save_as_button.text = "Save As..."
	save_as_button.pressed.connect(func(): save_dialog.popup_centered())
	bar.add_child(save_as_button)

	path_label = Label.new()
	path_label.text = "(new sequence)"
	path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(path_label)

	open_dialog = FileDialog.new()
	open_dialog.access = FileDialog.ACCESS_RESOURCES
	open_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	open_dialog.filters = PackedStringArray(["*.tres ; Godot Resource"])
	open_dialog.current_dir = "res://"
	open_dialog.size = Vector2i(800, 600)
	open_dialog.file_selected.connect(_on_open_file_selected)
	add_child(open_dialog)

	save_dialog = FileDialog.new()
	save_dialog.access = FileDialog.ACCESS_RESOURCES
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.filters = PackedStringArray(["*.tres ; Godot Resource"])
	save_dialog.current_dir = "res://"
	save_dialog.size = Vector2i(800, 600)
	save_dialog.file_selected.connect(_on_save_file_selected)
	add_child(save_dialog)

	return bar

func _build_sequence_fields() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var header := Label.new()
	header.text = "Sequence"
	header.add_theme_font_size_override("font_size", 16)
	box.add_child(header)

	var id_row := HBoxContainer.new()
	id_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(id_row)
	var id_label := Label.new()
	id_label.text = "sequence_id:"
	id_row.add_child(id_label)
	sequence_id_edit = LineEdit.new()
	sequence_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sequence_id_edit.text_changed.connect(func(value: String):
		if current_sequence == null or _refreshing_fields:
			return
		current_sequence.sequence_id = StringName(value)
		_mark_dirty()
	)
	id_row.add_child(sequence_id_edit)

	var quest_row := HBoxContainer.new()
	quest_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(quest_row)
	var quest_label := Label.new()
	quest_label.text = "quest_id:"
	quest_row.add_child(quest_label)
	quest_id_spin = SpinBox.new()
	quest_id_spin.min_value = -1
	quest_id_spin.max_value = 1000000
	quest_id_spin.allow_greater = true
	quest_id_spin.step = 1
	quest_id_spin.rounded = true
	quest_id_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_id_spin.value_changed.connect(func(value: float):
		if current_sequence == null or _refreshing_fields:
			return
		current_sequence.quest_id = int(value)
		_mark_dirty()
	)
	quest_row.add_child(quest_id_spin)

	var priority_row := HBoxContainer.new()
	priority_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(priority_row)
	var priority_label := Label.new()
	priority_label.text = "priority:"
	priority_row.add_child(priority_label)
	priority_spin = SpinBox.new()
	priority_spin.min_value = -1000000
	priority_spin.max_value = 1000000
	priority_spin.allow_greater = true
	priority_spin.allow_lesser = true
	priority_spin.step = 1
	priority_spin.rounded = true
	priority_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	priority_spin.value_changed.connect(func(value: float):
		if current_sequence == null or _refreshing_fields:
			return
		current_sequence.priority = int(value)
		_mark_dirty()
	)
	priority_row.add_child(priority_spin)

	var cancel_row := HBoxContainer.new()
	box.add_child(cancel_row)
	can_cancel_check = CheckBox.new()
	can_cancel_check.text = "can_cancel"
	can_cancel_check.toggled.connect(func(value: bool):
		if current_sequence == null or _refreshing_fields:
			return
		current_sequence.can_cancel = value
		_mark_dirty()
	)
	cancel_row.add_child(can_cancel_check)

	var start_row := HBoxContainer.new()
	start_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(start_row)
	var start_label := Label.new()
	start_label.text = "start_entry_id:"
	start_row.add_child(start_label)
	start_id_field = IDField.new()
	start_id_field.value_changed.connect(func(value: String):
		if current_sequence == null or _refreshing_fields:
			return
		current_sequence.start_entry_id = StringName(value)
		_mark_dirty()
	)
	start_row.add_child(start_id_field)

	var states_label := Label.new()
	states_label.text = "state_entries:"
	box.add_child(states_label)
	state_entries_box = VBoxContainer.new()
	box.add_child(state_entries_box)
	var add_state_button := Button.new()
	add_state_button.text = "+ Add State Entry"
	add_state_button.pressed.connect(_on_add_state_entry)
	box.add_child(add_state_button)

	return box

func _new_sequence() -> void:
	current_sequence = DialogueSequence.new()
	current_path = ""
	_dirty = false
	entry_list.set_sequence(current_sequence)
	entry_editor.set_sequence(current_sequence)
	entry_editor.clear()
	_refresh_sequence_fields()
	_update_path_label()
	_revalidate()

func _refresh_sequence_fields() -> void:
	if current_sequence == null:
		return
	_refreshing_fields = true
	sequence_id_edit.text = String(current_sequence.sequence_id)
	quest_id_spin.value = current_sequence.quest_id
	priority_spin.value = current_sequence.priority
	start_id_field.set_value(String(current_sequence.start_entry_id))
	can_cancel_check.button_pressed = current_sequence.can_cancel
	start_id_field.set_options(entry_editor.get_entry_ids())
	_rebuild_state_entries()
	_refreshing_fields = false

func _rebuild_state_entries() -> void:
	if state_entries_box == null or current_sequence == null:
		return
	for child in state_entries_box.get_children():
		child.queue_free()
	_state_entry_keys.clear()
	_state_entry_targets.clear()
	_state_target_fields.clear()
	for state in current_sequence.state_entries.keys():
		_state_entry_keys.append(StringName(state))
		_state_entry_targets.append(
			StringName(current_sequence.state_entries.get(StringName(state), &""))
		)
	for index in _state_entry_keys.size():
		state_entries_box.add_child(_build_state_entry_row(index))

func _build_state_entry_row(index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var state_edit := LineEdit.new()
	state_edit.placeholder_text = "state"
	state_edit.text = String(_state_entry_keys[index])
	state_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_edit.text_changed.connect(func(value: String):
		_on_state_key_changed(index, value)
	)
	row.add_child(state_edit)

	var target_field := IDField.new("entry_id")
	target_field.set_value(String(_state_entry_targets[index]))
	target_field.set_options(entry_editor.get_entry_ids())
	target_field.value_changed.connect(func(value: String):
		_on_state_target_changed(index, value)
	)
	row.add_child(target_field)
	_state_target_fields.append(target_field)

	var remove_button := Button.new()
	remove_button.text = "x"
	remove_button.tooltip_text = "Remove state entry"
	remove_button.pressed.connect(func(): _remove_state_entry(index))
	row.add_child(remove_button)

	return row

func _on_add_state_entry() -> void:
	if current_sequence == null:
		return
	var key := StringName(_next_default_state_key())
	current_sequence.state_entries[key] = &""
	_rebuild_state_entries()
	_mark_dirty()

func _next_default_state_key() -> String:
	var index := 1
	var existing: Dictionary = {}
	for state in current_sequence.state_entries.keys():
		existing[String(state)] = true
	while existing.has("new_state_%d" % index):
		index += 1
	return "new_state_%d" % index

func _on_state_key_changed(index: int, value: String) -> void:
	if current_sequence == null or index < 0 or index >= _state_entry_keys.size():
		return
	var old_key := _state_entry_keys[index]
	var target := _state_entry_targets[index]
	var new_key := StringName(value)
	if old_key != new_key:
		current_sequence.state_entries.erase(old_key)
		current_sequence.state_entries[new_key] = target
		_state_entry_keys[index] = new_key
	_mark_dirty()

func _on_state_target_changed(index: int, value: String) -> void:
	if current_sequence == null or index < 0 or index >= _state_entry_keys.size():
		return
	var key := _state_entry_keys[index]
	_state_entry_targets[index] = StringName(value)
	current_sequence.state_entries[key] = _state_entry_targets[index]
	_mark_dirty()

func _remove_state_entry(index: int) -> void:
	if current_sequence == null or index < 0 or index >= _state_entry_keys.size():
		return
	current_sequence.state_entries.erase(_state_entry_keys[index])
	_state_entry_targets.remove_at(index)
	_rebuild_state_entries()
	_mark_dirty()

func _on_open_file_selected(path: String) -> void:
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded == null or not (loaded is DialogueSequence):
		push_error("Selected file is not a DialogueSequence resource: %s" % path)
		return
	current_sequence = loaded
	current_path = path
	_dirty = false
	entry_list.set_sequence(current_sequence)
	entry_editor.set_sequence(current_sequence)
	entry_editor.clear()
	_refresh_sequence_fields()
	_update_path_label()
	_revalidate()

func _on_save_pressed() -> void:
	if current_path == "":
		save_dialog.popup_centered()
		return
	_save_to(current_path)

func _on_save_file_selected(path: String) -> void:
	_save_to(path)

func _save_to(path: String) -> void:
	var err := ResourceSaver.save(current_sequence, path)
	if err != OK:
		push_error("Failed to save dialogue sequence: %s (error %d)" % [path, err])
		return
	current_path = path
	_dirty = false
	_update_path_label()

func _update_path_label() -> void:
	var display_path := current_path if current_path != "" else "(unsaved)"
	var dirty_marker := " *" if _dirty else ""
	path_label.text = display_path + dirty_marker

func _on_entry_selected(entry: DialogueEntry) -> void:
	if entry == null:
		entry_editor.clear()
	else:
		entry_editor.edit_entry(entry)

func _on_entries_changed() -> void:
	_mark_dirty()
	entry_editor.refresh_id_options()
	start_id_field.set_options(entry_editor.get_entry_ids())
	_refresh_state_entry_options()

func _on_entry_editor_changed() -> void:
	_mark_dirty()
	entry_list.refresh()
	entry_editor.refresh_id_options()
	start_id_field.set_options(entry_editor.get_entry_ids())
	_refresh_state_entry_options()

func _refresh_state_entry_options() -> void:
	var ids := entry_editor.get_entry_ids()
	for target_field in _state_target_fields:
		target_field.set_options(ids)

func _mark_dirty() -> void:
	_dirty = true
	_update_path_label()
	_revalidate()

func _revalidate() -> void:
	validation_list.clear()
	var issues := DialogueValidator.validate(current_sequence)
	if issues.is_empty():
		validation_list.add_item("No issues found.")
	else:
		for issue in issues:
			validation_list.add_item(issue)
