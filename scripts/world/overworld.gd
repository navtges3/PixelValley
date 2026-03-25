extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var zone_message_label: ZoneMessageLabel = $ZoneMessageLabel

func _ready() -> void:
	for zone in get_tree().get_nodes_in_group("trigger_zone"):
		zone = zone as TriggerZone
		if zone == null:
			continue
		zone.zone_entered.connect(_on_zone_entered)
		zone.zone_locked.connect(_on_zone_locked.bind(zone))

func place_player_at_entrance(entrance_id: String) -> void:
	for zone in get_tree().get_nodes_in_group("trigger_zone"):
		zone = zone as TriggerZone
		if entrance_id == zone.entrance_id:
			$Player.place_at_entrance(zone)
			return
	push_warning("Entrance not found: ", entrance_id)

func _on_zone_entered(zone: TriggerZone) -> void:
	player.on_zone_entered(zone)

func _on_zone_locked(message: String, zone: TriggerZone) -> void:
	zone_message_label.show_message(message, zone.global_position)
