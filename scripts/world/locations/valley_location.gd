extends BaseLocation
class_name ValleyLocation

const DEFAULT_SPAWN_ENTRANCE_ID := "village"

@onready var cave_closed: StaticBody2D = $YSortedWorld/Mountains/CaveClosed
@onready var cave_closed_collision: CollisionPolygon2D = $YSortedWorld/Mountains/CaveClosed/CollisionPolygon2D
@onready var camp_gate_closed: StaticBody2D = $YSortedWorld/CampWalls/CampGateClosed
@onready var village_trigger_zone: TriggerZone = $TriggerZones/VillageTriggerZone
@onready var forest_trigger_zone: TriggerZone = $TriggerZones/ForestTriggerZone
@onready var war_camp_trigger_zone: TriggerZone = $TriggerZones/WarCampTriggerZone
@onready var cave_trigger_zone: TriggerZone = $TriggerZones/CaveTriggerZone

func _ready() -> void:
	super._ready()
	village_trigger_zone.screen_target = ScreenManager.ScreenName.VILLAGE
	forest_trigger_zone.screen_target = ScreenManager.ScreenName.FOREST
	war_camp_trigger_zone.screen_target = ScreenManager.ScreenName.WAR_CAMP
	cave_trigger_zone.screen_target = ScreenManager.ScreenName.CAVE
	var war_camp_unlocked := WorldManager.is_unlocked(WarCampLocation.LOCATION_ID)
	camp_gate_closed.visible = !war_camp_unlocked
	var cave_unlocked := WorldManager.is_unlocked(CaveLocation.LOCATION_ID)
	cave_closed.visible = !cave_unlocked
	cave_closed_collision.disabled = cave_unlocked

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.VALLEY

func _apply_default_player_placement() -> void:
	super._apply_default_player_placement()
	if player == null or GameState.pre_combat_position != Vector2.ZERO:
		return
	place_player_at_entrance(DEFAULT_SPAWN_ENTRANCE_ID)
