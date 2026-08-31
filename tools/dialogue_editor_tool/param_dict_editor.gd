## Editable UI for a DialogueCondition/DialogueAction `parameters` dictionary
## (Dictionary[StringName, Variant]). Each row is a key, a type selector,
## and a value control appropriate to that type.
class_name ParamDictEditor
extends VBoxContainer

signal changed()

const TYPE_NAMES := ["String", "StringName", "Int", "Float", "Bool"]

var _entries: Array = []  # Array of {"key": String, "value": Variant}

func set_dictionary(dict: Dictionary) -> void:
	_entries.clear()
	for key in dict.keys():
		_entries.append({"key": String(key), "value": dict[key]})
	_rebuild()

func get_dictionary() -> Dictionary:
	var result: Dictionary[StringName, Variant] = {}
	for e in _entries:
		var key_text: String = e.key
		if key_text.strip_edges() == "":
			continue
		result[StringName(key_text)] = e.value
	return result

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	for i in _entries.size():
		add_child(_build_row(i))

	var add_button := Button.new()
	add_button.text = "+ Add Parameter"
	add_button.pressed.connect(func():
		_entries.append({"key": "", "value": ""})
		_rebuild()
		changed.emit()
	)
	add_child(add_button)

func _build_row(index: int) -> HBoxContainer:
	var entry: Dictionary = _entries[index]
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var key_edit := LineEdit.new()
	key_edit.placeholder_text = "key"
	key_edit.custom_minimum_size = Vector2(90, 0)
	key_edit.text = entry.key
	key_edit.text_changed.connect(func(t):
		_entries[index].key = t
		changed.emit()
	)
	row.add_child(key_edit)

	var type_option := OptionButton.new()
	for type_name in TYPE_NAMES:
		type_option.add_item(type_name)
	type_option.selected = _infer_type(entry.value)
	type_option.item_selected.connect(func(i):
		_entries[index].value = _default_for_type(i)
		_rebuild()
		changed.emit()
	)
	row.add_child(type_option)

	row.add_child(_make_value_control(index, type_option.selected, entry.value))

	var remove_button := Button.new()
	remove_button.text = "x"
	remove_button.pressed.connect(func():
		_entries.remove_at(index)
		_rebuild()
		changed.emit()
	)
	row.add_child(remove_button)

	return row

func _infer_type(value: Variant) -> int:
	match typeof(value):
		TYPE_STRING_NAME:
			return 1
		TYPE_INT:
			return 2
		TYPE_FLOAT:
			return 3
		TYPE_BOOL:
			return 4
		_:
			return 0

func _default_for_type(index: int) -> Variant:
	match index:
		1:
			return &""
		2:
			return 0
		3:
			return 0.0
		4:
			return false
		_:
			return ""

func _make_value_control(index: int, type_index: int, value: Variant) -> Control:
	match type_index:
		2:  # Int
			var spin := SpinBox.new()
			spin.min_value = -1000000
			spin.max_value = 1000000
			spin.step = 1
			spin.rounded = true
			spin.value = float(value) if typeof(value) in [TYPE_INT, TYPE_FLOAT] else 0.0
			spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spin.value_changed.connect(func(v):
				_entries[index].value = int(v)
				changed.emit()
			)
			return spin
		3:  # Float
			var spin_f := SpinBox.new()
			spin_f.min_value = -1000000
			spin_f.max_value = 1000000
			spin_f.step = 0.01
			spin_f.value = float(value) if typeof(value) in [TYPE_INT, TYPE_FLOAT] else 0.0
			spin_f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spin_f.value_changed.connect(func(v):
				_entries[index].value = v
				changed.emit()
			)
			return spin_f
		4:  # Bool
			var check := CheckBox.new()
			check.button_pressed = bool(value)
			check.toggled.connect(func(v):
				_entries[index].value = v
				changed.emit()
			)
			return check
		1:  # StringName
			var line_sn := LineEdit.new()
			line_sn.text = String(value)
			line_sn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_sn.text_changed.connect(func(t):
				_entries[index].value = StringName(t)
				changed.emit()
			)
			return line_sn
		_:  # String
			var line := LineEdit.new()
			line.text = String(value)
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.text_changed.connect(func(t):
				_entries[index].value = t
				changed.emit()
			)
			return line
