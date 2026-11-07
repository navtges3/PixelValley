extends Node
class_name RegionManager

signal active_region_changed(previous_region: LocationRegion, new_region: LocationRegion)

var active_region: LocationRegion = null

func get_active_region() -> LocationRegion:
	return active_region

func get_active_region_id() -> StringName:
	return active_region.display_name

func refresh_player_region(player: Player) -> void:
	pass
