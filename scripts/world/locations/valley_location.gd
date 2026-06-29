extends BaseLocation
class_name ValleyLocation

@onready var camp_gate_closed: StaticBody2D = $WoodWalls/CampGateClosed
@onready var cave_closed: StaticBody2D = $CaveWalls/CaveClosed
@onready var village_trigger_zone = $TriggerZones/VillageTriggerZone
@onready var forest_trigger_zone = $TriggerZones/ForestTriggerZone
@onready var war_camp_trigger_zone = $TriggerZones/WarCampTriggerZone
@onready var cave_trigger_zone = $TriggerZones/CaveTriggerZone

func _ready() -> void:
	super._ready()
	village_trigger_zone.screen_target = ScreenManager.ScreenName.VILLAGE
	forest_trigger_zone.screen_target = ScreenManager.ScreenName.FOREST
	war_camp_trigger_zone.screen_target = ScreenManager.ScreenName.WAR_CAMP
	cave_trigger_zone.screen_target = ScreenManager.ScreenName.CAVE
	
	var war_camp_unlocked = WorldManager.is_unlocked(WarCampLocation.LOCATION_ID)
	_set_blocker_enabled(camp_gate_closed, not war_camp_unlocked)
	
	var cave_unlocked = WorldManager.is_unlocked(CaveLocation.LOCATION_ID)
	_set_blocker_enabled(cave_closed, not cave_unlocked)

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.VALLEY

func _set_blocker_enabled(blocker: StaticBody2D, enabled: bool) -> void:
	blocker.visible = enabled
	blocker.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	for child in blocker.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = not enabled
