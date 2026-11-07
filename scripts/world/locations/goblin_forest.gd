extends BaseCombatLocation
class_name GoblinForestLocation

const LOCATION_ID := "forest"

@onready var region_manager: RegionManager = $RegionManager
@onready var exit_trigger_zone: TriggerZone = $TriggerZones/ExitTriggerZone

var world_hud: WorldHUD

func _get_location_id() -> String:
	return LOCATION_ID

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.FOREST

func _on_location_ready() -> void:
	super._on_location_ready()
	world_hud = ScreenManager.get_world_hud() as WorldHUD
	if region_manager != null:
		region_manager.active_region_changed.connect(_on_active_region_changed)
	exit_trigger_zone.screen_target = ScreenManager.ScreenName.VALLEY

func _on_player_attached() -> void:
	super._on_player_attached()
	if region_manager != null and player != null:
		region_manager.refresh_player_region(player)

func _on_active_region_changed(_prev_region: LocationRegion, new_region: LocationRegion) -> void:
	if new_region == null:
		return
	if world_hud == null:
		return
	if new_region.show_notification:
		world_hud.show_location_name(new_region.display_name)
