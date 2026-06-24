extends Area2D
class_name TriggerZone

@export var locked: bool = false
@export var entrance_id: String = ""
@export var locked_message: String = "The path is blocked."
@export var screen_target: ScreenManager.ScreenName = ScreenManager.ScreenName.NONE
@export var screen_data: int = -1

var _player_inside: bool = false
var _player: Player = null

func _ready() -> void:
	if locked and WorldManager.is_unlocked(entrance_id):
		locked = false

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true
		_player = body
		if locked:
			_player.show_prompt(locked_message)
		else:
			_player.on_zone_entered(self)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false
		if _player != null:
			if locked:
				_player.clear_prompt(locked_message)
			else:
				_player.clear_prompt()
		_player = null

func unlock() -> void:
	if locked:
		locked = false
		WorldManager.unlock_location(entrance_id)
