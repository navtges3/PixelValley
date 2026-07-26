extends Area2D
class_name InteractArea

signal interacted

@export var prompt_text: String = "Press E to Interact"

var _player_inside: bool = false
var _player: Player = null
var _enabled: bool = true

func set_enabled(enabled: bool) -> void:
	if _enabled == enabled:
		return
	_enabled = enabled
	set_process_unhandled_input(_enabled)
	monitoring = _enabled
	if not _enabled and _player != null:
		_player.clear_prompt(prompt_text)
		_player_inside = false
		_player = null

func _unhandled_input(event: InputEvent) -> void:
	if (not _enabled or not _player_inside
		or not event.is_action_pressed("interact")
		or _player == null or _player.movement_blocked):
		return
	get_viewport().set_input_as_handled()
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
