extends StaticBody2D
class_name Building

@export var entrance_id: String = ""
@export var screen_target: ScreenManager.ScreenName = ScreenManager.ScreenName.NONE

signal building_entered(building: Building)

@onready var entrance_zone: Area2D = $EntranceZone

func _ready() -> void:
	entrance_zone.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	building_entered.emit(self)
