## Editor for a single DialogueCondition (condition_id + parameters).
class_name ConditionRowEditor
extends PanelContainer

signal changed()
signal remove_requested()

var condition: DialogueCondition
var _id_edit: LineEdit
var _param_editor: ParamDictEditor

func set_condition(cond: DialogueCondition) -> void:
	condition = cond
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var vbox := VBoxContainer.new()
	add_child(vbox)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(header)

	var label := Label.new()
	label.text = "Condition:"
	header.add_child(label)

	_id_edit = LineEdit.new()
	_id_edit.placeholder_text = "condition_id"
	_id_edit.text = String(condition.condition_id)
	_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_id_edit.text_changed.connect(func(t):
		condition.condition_id = StringName(t)
		changed.emit()
	)
	header.add_child(_id_edit)

	var remove_button := Button.new()
	remove_button.text = "Remove Condition"
	remove_button.pressed.connect(func(): remove_requested.emit())
	header.add_child(remove_button)

	_param_editor = ParamDictEditor.new()
	_param_editor.set_dictionary(condition.parameters)
	_param_editor.changed.connect(func():
		condition.parameters = _param_editor.get_dictionary()
		changed.emit()
	)
	vbox.add_child(_param_editor)
