extends GameWindow
class_name ConfirmationWindow

signal confirmed
signal cancelled

@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var message_label: Label = $PanelContainer/MarginContainer/VBoxContainer/MessageLabel
@onready var confirm_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ButtonRow/ConfirmButton
@onready var cancel_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ButtonRow/CancelButton

func setup(title: String, message: String) -> void:
	title_label.text = title
	message_label.text = message

func _get_default_focus_target() -> Control:
	return cancel_button

func _handle_cancel() -> void:
	_on_cancel_button_pressed()

func _on_confirm_button_pressed() -> void:
	close()
	confirmed.emit()

func _on_cancel_button_pressed() -> void:
	close()
	cancelled.emit()
