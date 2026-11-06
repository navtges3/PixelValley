extends Area2D
class_name LocationRegion

signal player_entered_region(region: LocationRegion)
signal player_exited_region(region: LocationRegion)

@export_group("Region")
@export var region_id: StringName
@export var display_name: String = ""

@export_group("Display")
@export var show_notification: bool = true
