extends BaseLocation
class_name OverworldLocation

@onready var zone_message_label: ZoneMessageLabel = $ZoneMessageLabel

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.OVERWORLD

func _connect_zone(zone: TriggerZone) -> void:
	super._connect_zone(zone)
	zone.zone_locked.connect(_on_zone_locked.bind(zone))

func _on_zone_locked(message: String, zone: TriggerZone) -> void:
	zone_message_label.show_message(message, zone.global_position)
