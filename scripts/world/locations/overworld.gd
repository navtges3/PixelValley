extends BaseLocation
class_name OverworldLocation

@onready var zone_message_label: ZoneMessageLabel = $ZoneMessageLabel
@onready var camp_gate_closed: StaticBody2D = $WoodWalls/CampGateClosed
@onready var camp_gate_open: StaticBody2D = $WoodWalls/CampGateOpen

func _ready() -> void:
	super._ready()
	var war_camp_unlocked := WorldManager.is_unlocked(WarCampLocation.LOCATION_ID)
	camp_gate_closed.visible = !war_camp_unlocked
	camp_gate_open.visible = war_camp_unlocked

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.OVERWORLD

func _connect_zone(zone: TriggerZone) -> void:
	super._connect_zone(zone)
	zone.zone_locked.connect(_on_zone_locked.bind(zone))

func _on_zone_locked(message: String, zone: TriggerZone) -> void:
	zone_message_label.show_message(message, zone.global_position)
