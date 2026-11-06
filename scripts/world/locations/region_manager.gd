extends Node
class_name RegionManager

signal active_region_changed(previous_region: LocationRegion, new_region: LocationRegion)

func get_active_region() -> LocationRegion:
	return null

func get_active_region_id() -> StringName:
	return ""

func refresh_player_region(player: Player) -> void:
	pass
