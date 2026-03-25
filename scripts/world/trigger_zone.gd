extends Area2D
class_name TriggerZone

@export var locked: bool = false
@export var entrance_id: String = ""
@export var locked_message: String = "The path is blocked."
@export var screen_target: ScreenManager.ScreenName = ScreenManager.ScreenName.VILLAGE

signal zone_entered(zone: TriggerZone)
signal zone_locked(message: String)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if locked and GameState.is_zone_unlocked(entrance_id):
		locked = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if locked:
		emit_signal("zone_locked", locked_message)
	else:
		emit_signal("zone_entered", self)

func unlock() -> void:
	if locked:
		locked = false
		GameState.unlock_zone(entrance_id)
