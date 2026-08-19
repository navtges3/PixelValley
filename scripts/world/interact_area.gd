extends Area2D
class_name InteractArea

signal interacted

@export var prompt_label: String = "Interact"

var _player_inside: bool = false
var _player: Player = null
var _enabled: bool = true
var _displayed_prompt_text: String = ""

func _ready() -> void:
	InputManager.prompt_context_changed.connect(_on_prompt_context_changed)
	visibility_changed.connect(_on_visibility_changed)

func set_enabled(enabled: bool) -> void:
	if _enabled == enabled:
		return
	_enabled = enabled
	set_process_unhandled_input(_enabled)
	monitoring = _enabled
	if not _enabled and _player != null:
		_clear_player_prompt()
		_player_inside = false
		_player = null

func _clear_player_prompt() -> void:
	if _player !=  null and not _displayed_prompt_text.is_empty():
		_player.clear_prompt(_displayed_prompt_text, self)
	_displayed_prompt_text = ""

func _exit_tree() -> void:
	_clear_player_prompt()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true
		_player = body
		_refresh_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_clear_player_prompt()
		_player_inside = false
		_player = null

func _on_prompt_context_changed() -> void:
	_refresh_prompt()

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_refresh_prompt()
	else:
		_clear_player_prompt()

func _refresh_prompt() -> void:
	if (not _enabled or not is_visible_in_tree()
		or _player == null or not _player_inside):
		return
	var refreshed_text := InputManager.format_action_prompt(&"interact", prompt_label)
	if not _displayed_prompt_text.is_empty() and _displayed_prompt_text != refreshed_text:
		_player.clear_prompt(_displayed_prompt_text, self)
	_displayed_prompt_text = refreshed_text
	_player.show_prompt(_displayed_prompt_text, self)

func _unhandled_input(event: InputEvent) -> void:
	if (not _enabled or not _player_inside
		or event.is_echo()
		or not event.is_action_pressed("interact")
		or _player == null or _player.movement_blocked):
		return
	get_viewport().set_input_as_handled()
	interacted.emit()
