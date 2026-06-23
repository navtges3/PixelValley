extends Area2D
class_name InteractArea

signal interacted

@export var prompt_text: String = "Press E to Interact"

@onready var prompt_label: Label = $PromptLabel

var _player_inside: bool = false
var _player: Player = null

func _ready() -> void:
	prompt_label.hide()

func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		interacted.emit()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true
		_player = body
		_player.show_prompt(prompt_text)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false
		if _player != null:
			_player.clear_prompt(prompt_text)
		_player = null
