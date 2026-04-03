extends BaseCombatLocation
class_name WarCampLocation

const LOCATION_ID := "war_camp"

func _get_location_id() -> String:
	return LOCATION_ID

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.WAR_CAMP
