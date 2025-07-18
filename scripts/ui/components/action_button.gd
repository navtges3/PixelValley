extends Button

signal action_pressed(action_data: Dictionary)

var action_data: Dictionary

func _ready() -> void:
	connect("pressed", Callable(self, "_on_pressed"))

func setup(data: Dictionary, label_text: String) -> void:
	self.action_data = data
	self.text = label_text

func _on_pressed():
	emit_signal("action_pressed", action_data)