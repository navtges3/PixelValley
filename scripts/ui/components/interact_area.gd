extends Area2D
class_name InteractArea

signal interacted

@export var prompt_text: String = "Press E to Interact"

@onready var prompt_label: Label = $PromptLabel

var _player_inside: bool = false

func _ready() -> void:
	prompt_label.text = prompt_text
	prompt_label.hide()

func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		interacted.emit()

func _on_body_entered(body: Node2D) -> void:
	print("Player has entered")
	if body is Player:
		_player_inside = true
		prompt_label.show()

func _on_body_exited(body: Node2D) -> void:
	print("Player has exited")
	if body is Player:
		_player_inside = false
		prompt_label.hide()
