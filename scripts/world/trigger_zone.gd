extends Area2D
class_name TriggerZone

@export var locked: bool = false
@export var entrance_id: String = ""
@export var locked_message: String = "The path is blocked."
@export var prompt_text: String = ""
@export var screen_target: ScreenManager.ScreenName = ScreenManager.ScreenName.NONE
@export var screen_data: int = -1

signal zone_entered(zone: TriggerZone)
signal zone_locked(message: String)
signal zone_prompted(message: String)
signal zone_exited(zone: TriggerZone)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if locked and WorldManager.is_unlocked(entrance_id):
		locked = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if locked:
		emit_signal("zone_prompted", locked_message)
		emit_signal("zone_locked", locked_message)
	else:
		if not prompt_text.is_empty():
			emit_signal("zone_prompted", prompt_text)
		emit_signal("zone_entered", self)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	emit_signal("zone_exited", self)

func unlock() -> void:
	if locked:
		locked = false
		WorldManager.unlock_location(entrance_id)
