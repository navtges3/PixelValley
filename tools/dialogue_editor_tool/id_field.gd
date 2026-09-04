## A small composite control for editing a StringName-style id field
## (entry_id references like next_entry_id).
##
## Shows a free-text LineEdit next to a MenuButton that lists the current
## entry ids in the sequence, so the user can either type a custom id
## or pick an existing one from the dropdown.
class_name IDField
extends HBoxContainer

signal value_changed(new_value: String)

var _line_edit: LineEdit
var _picker: MenuButton
var _options: Array[String] = []

func _init(placeholder: String = "") -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_line_edit = LineEdit.new()
	_line_edit.placeholder_text = placeholder
	_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line_edit.text_changed.connect(_on_text_changed)
	add_child(_line_edit)

	_picker = MenuButton.new()
	_picker.text = "..."
	_picker.tooltip_text = "Pick an existing entry id"
	add_child(_picker)

	var popup := _picker.get_popup()
	popup.id_pressed.connect(_on_option_picked)

func _on_text_changed(new_text: String) -> void:
	value_changed.emit(new_text)

func _on_option_picked(id: int) -> void:
	if id == -1:
		set_value("")
		value_changed.emit("")
		return
	if id < 0 or id >= _options.size():
		return
	set_value(_options[id])
	value_changed.emit(_options[id])

func set_value(value: String) -> void:
	_line_edit.text = value

func get_value() -> String:
	return _line_edit.text

func set_options(options: Array[String]) -> void:
	_options = options
	var popup := _picker.get_popup()
	popup.clear()
	popup.add_item("(none)", -1)
	for i in options.size():
		popup.add_item(options[i], i)
