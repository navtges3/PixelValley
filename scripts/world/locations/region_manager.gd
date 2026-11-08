extends Node
class_name RegionManager

signal active_region_changed(previous_region: LocationRegion, new_region: LocationRegion)

var _active_region: LocationRegion = null
var _regions: Array[LocationRegion] = []
var _overlapping_regions: Array[LocationRegion] = []
var _player: Player

func _ready() -> void:
	_discover_regions()

func _discover_regions() -> void:
	_regions.clear()
	for child in get_children():
		var region := child as LocationRegion
		if region == null:
			continue
		if region.region_id.is_empty():
			push_error("Region '%s' has no ID." % region.name)
			continue
		_regions.append(region)
		region.player_entered_region.connect(_on_region_entered)
		region.player_exited_region.connect(_on_region_exited)

func get_active_region() -> LocationRegion:
	return _active_region

func get_active_region_id() -> StringName:
	if _active_region == null:
		return &""
	return _active_region.region_id

func _on_region_entered(region: LocationRegion) -> void:
	if not _overlapping_regions.has(region):
		_overlapping_regions.append(region)
	_update_active_region()

func _on_region_exited(region: LocationRegion) -> void:
	_overlapping_regions.erase(region)
	_update_active_region()

func _update_active_region() -> void:
	var new_region: LocationRegion = null
	if not _overlapping_regions.is_empty():
		new_region = _overlapping_regions.back()
	if new_region == _active_region:
		return
	var previous_region := _active_region
	_active_region = new_region
	active_region_changed.emit(previous_region, _active_region)

func refresh_player_region(player: Player) -> void:
	_player = player
	_refresh_player_region_deferred.call_deferred()

func _refresh_player_region_deferred() -> void:
	if not is_instance_valid(_player):
		return
	await get_tree().physics_frame
	_overlapping_regions.clear()
	for region in _regions:
		if not is_instance_valid(region):
			continue
		if region.overlaps_body(_player):
			_overlapping_regions.append(region)
	_update_active_region()
