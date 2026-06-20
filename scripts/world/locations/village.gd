extends BaseLocation
class_name VillageLocation

@onready var exit_trigger_zone: TriggerZone = $TriggerZones/ExitTriggerZone
@onready var quest_trigger_zone: TriggerZone = $TriggerZones/QuestTriggerZone

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.VILLAGE

func _on_location_ready() -> void:
	exit_trigger_zone.screen_target = ScreenManager.ScreenName.VALLEY
	quest_trigger_zone.screen_target = ScreenManager.ScreenName.QUEST
	for building in get_tree().get_nodes_in_group("building"):
		(building as Building).building_entered.connect(_on_building_entered)

func _on_building_entered(building: Building) -> void:
	GameState.set_player_location(ScreenManager.ScreenName.VILLAGE, building.entrance_id)
	ScreenManager.go_to_screen(building.screen_target, building.entrance_id)
