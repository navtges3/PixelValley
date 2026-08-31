## Editor for a single DialogueResponse: text, next_entry_id, and its own
## nested conditions / actions lists.
class_name ResponseEditor
extends PanelContainer

signal changed()
signal remove_requested()

var response: DialogueResponse
var _entry_ids_provider: Callable  # func() -> Array[String]

var _text_edit: TextEdit
var _next_id_field: IDField
var _conditions_box: VBoxContainer
var _actions_box: VBoxContainer

func set_response(resp: DialogueResponse, entry_ids_provider: Callable) -> void:
	response = resp
	_entry_ids_provider = entry_ids_provider
	_rebuild()

func refresh_id_options() -> void:
	if _next_id_field:
		_next_id_field.set_options(_entry_ids_provider.call())

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var vbox := VBoxContainer.new()
	add_child(vbox)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(header)

	var label := Label.new()
	label.text = "Response"
	header.add_child(label)

	var remove_button := Button.new()
	remove_button.text = "Remove Response"
	remove_button.pressed.connect(func(): remove_requested.emit())
	header.add_child(remove_button)

	_text_edit = TextEdit.new()
	_text_edit.text = response.text
	_text_edit.custom_minimum_size = Vector2(0, 50)
	_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_text_edit.text_changed.connect(func():
		response.text = _text_edit.text
		changed.emit()
	)
	vbox.add_child(_text_edit)

	var next_row := HBoxContainer.new()
	next_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(next_row)
	var next_label := Label.new()
	next_label.text = "Next Entry:"
	next_row.add_child(next_label)

	_next_id_field = IDField.new()
	_next_id_field.set_value(String(response.next_entry_id))
	_next_id_field.set_options(_entry_ids_provider.call())
	_next_id_field.value_changed.connect(func(v):
		response.next_entry_id = StringName(v)
		changed.emit()
	)
	next_row.add_child(_next_id_field)

	var cond_label := Label.new()
	cond_label.text = "Conditions"
	vbox.add_child(cond_label)
	_conditions_box = VBoxContainer.new()
	vbox.add_child(_conditions_box)
	_rebuild_conditions()

	var add_cond_button := Button.new()
	add_cond_button.text = "+ Add Condition"
	add_cond_button.pressed.connect(func():
		response.conditions.append(DialogueCondition.new())
		_rebuild_conditions()
		changed.emit()
	)
	vbox.add_child(add_cond_button)

	var act_label := Label.new()
	act_label.text = "Actions"
	vbox.add_child(act_label)
	_actions_box = VBoxContainer.new()
	vbox.add_child(_actions_box)
	_rebuild_actions()

	var add_act_button := Button.new()
	add_act_button.text = "+ Add Action"
	add_act_button.pressed.connect(func():
		response.actions.append(DialogueAction.new())
		_rebuild_actions()
		changed.emit()
	)
	vbox.add_child(add_act_button)

func _rebuild_conditions() -> void:
	for child in _conditions_box.get_children():
		child.queue_free()
	for cond in response.conditions:
		var row := ConditionRowEditor.new()
		row.set_condition(cond)
		row.changed.connect(func(): changed.emit())
		row.remove_requested.connect(func():
			response.conditions.erase(cond)
			_rebuild_conditions()
			changed.emit()
		)
		_conditions_box.add_child(row)

func _rebuild_actions() -> void:
	for child in _actions_box.get_children():
		child.queue_free()
	for act in response.actions:
		var row := ActionRowEditor.new()
		row.set_action(act)
		row.changed.connect(func(): changed.emit())
		row.remove_requested.connect(func():
			response.actions.erase(act)
			_rebuild_actions()
			changed.emit()
		)
		_actions_box.add_child(row)
