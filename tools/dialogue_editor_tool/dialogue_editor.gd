## Root controller for the standalone Dialogue Editor tool.
## Run this scene directly (F6) from inside the Godot editor. It can open
## any DialogueConversation .tres resource in the project, edit it with a
## purpose-built UI instead of the generic inspector, and save it back.
extends Control

var current_conversation: DialogueConversation
var current_path: String = ""
var _dirty: bool = false

var entry_list: EntryListPanel
var entry_editor: EntryEditorPanel
var validation_list: ItemList
var path_label: Label
var conv_id_edit: LineEdit
var start_id_field: IDField
var can_cancel_check: CheckBox
var open_dialog: FileDialog
var save_dialog: FileDialog

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_new_conversation()

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

	left_panel.add_child(_build_conversation_fields())

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
	new_button.pressed.connect(_new_conversation)
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
	path_label.text = "(new conversation)"
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

func _build_conversation_fields() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var header := Label.new()
	header.text = "Conversation"
	header.add_theme_font_size_override("font_size", 16)
	box.add_child(header)

	var id_row := HBoxContainer.new()
	id_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(id_row)
	var id_label := Label.new()
	id_label.text = "conversation_id:"
	id_row.add_child(id_label)
	conv_id_edit = LineEdit.new()
	conv_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conv_id_edit.text_changed.connect(func(t):
		current_conversation.conversation_id = StringName(t)
		_mark_dirty()
	)
	id_row.add_child(conv_id_edit)

	var start_row := HBoxContainer.new()
	start_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(start_row)
	var start_label := Label.new()
	start_label.text = "start_entry_id:"
	start_row.add_child(start_label)
	start_id_field = IDField.new()
	start_id_field.value_changed.connect(func(v):
		current_conversation.start_entry_id = StringName(v)
		_mark_dirty()
	)
	start_row.add_child(start_id_field)

	var cancel_row := HBoxContainer.new()
	box.add_child(cancel_row)
	can_cancel_check = CheckBox.new()
	can_cancel_check.text = "can_cancel"
	can_cancel_check.toggled.connect(func(v):
		current_conversation.can_cancel = v
		_mark_dirty()
	)
	cancel_row.add_child(can_cancel_check)

	return box

func _new_conversation() -> void:
	current_conversation = DialogueConversation.new()
	current_path = ""
	_dirty = false
	entry_list.set_conversation(current_conversation)
	entry_editor.set_conversation(current_conversation)
	entry_editor.clear()
	_refresh_conversation_fields()
	_update_path_label()
	_revalidate()

func _refresh_conversation_fields() -> void:
	conv_id_edit.text = String(current_conversation.conversation_id)
	start_id_field.set_value(String(current_conversation.start_entry_id))
	can_cancel_check.button_pressed = current_conversation.can_cancel
	start_id_field.set_options(entry_editor.get_entry_ids())

func _on_open_file_selected(path: String) -> void:
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded == null or not (loaded is DialogueConversation):
		push_error("Selected file is not a DialogueConversation resource: %s" % path)
		return
	current_conversation = loaded
	current_path = path
	_dirty = false
	entry_list.set_conversation(current_conversation)
	entry_editor.set_conversation(current_conversation)
	entry_editor.clear()
	_refresh_conversation_fields()
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
	var err := ResourceSaver.save(current_conversation, path)
	if err != OK:
		push_error("Failed to save dialogue conversation: %s (error %d)" % [path, err])
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

func _on_entry_editor_changed() -> void:
	_mark_dirty()
	entry_list.refresh()
	start_id_field.set_options(entry_editor.get_entry_ids())

func _mark_dirty() -> void:
	_dirty = true
	_update_path_label()
	_revalidate()

func _revalidate() -> void:
	validation_list.clear()
	var issues := DialogueValidator.validate(current_conversation)
	if issues.is_empty():
		validation_list.add_item("No issues found.")
	else:
		for issue in issues:
			validation_list.add_item(issue)
