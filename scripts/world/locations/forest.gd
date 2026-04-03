extends BaseCombatLocation
class_name ForestLocation

const LOCATION_ID := "forest"

func _get_location_id() -> String:
	return LOCATION_ID

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.FOREST
