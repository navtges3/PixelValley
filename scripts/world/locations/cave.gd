extends BaseCombatLocation
class_name CaveLocation

const LOCATION_ID := "cave"

func _get_location_id() -> String:
	return LOCATION_ID

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.CAVE
