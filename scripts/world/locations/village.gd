extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var pause_window: Window = $PauseWindow

var _pending_entrance_id: String = ""

func _ready() -> void:
	for zone in get_tree().get_nodes_in_group("trigger_zone"):
		zone = zone as TriggerZone
		if zone == null:
			continue
		zone.zone_entered.connect(_on_zone_entered)
	player.set_sprite_frames(GameState.hero.world_visual)
	if _pending_entrance_id != "":
		place_player_at_entrance(_pending_entrance_id)

func place_player_at_entrance(entrance_id: String) -> void:
	GameState.set_player_location(ScreenManager.ScreenName.VILLAGE, entrance_id)
	if not is_node_ready():
		_pending_entrance_id = entrance_id
		return
	for zone in get_tree().get_nodes_in_group("trigger_zone"):
		zone = zone as TriggerZone
		if zone == null:
			continue
		if entrance_id == zone.entrance_id:
			$Player.place_at_entrance(zone)
			return
	push_warning("Entrance not found: ", entrance_id)

func _on_zone_entered(zone: TriggerZone) -> void:
	player.on_zone_entered(zone)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not pause_window.is_visible():
		pause_window.popup_centered()
