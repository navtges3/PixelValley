extends BaseCombatLocation
class_name WarCampLocation

const LOCATION_ID := "war_camp"

@onready var exit_trigger_zone: TriggerZone = $TriggerZones/ExitTriggerZone

func _get_location_id() -> String:
	return LOCATION_ID

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.WAR_CAMP

func _on_location_ready() -> void:
	super._on_location_ready()
	exit_trigger_zone.screen_target = ScreenManager.ScreenName.VALLEY
