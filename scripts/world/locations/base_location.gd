extends Node2D
class_name BaseLocation

const WORLD_HUD = preload("res://scenes/ui/hud/world_hud.tscn")

@onready var pause_window: Window = $PauseWindow
@onready var player: Player = $Player

var _pending_entraince_id: String = ""

func _ready() -> void:
	for zone in get_tree().get_nodes_in_group("trigger_zone"):
		zone = zone as TriggerZone
		if zone == null:
			continue
		_connect_zone(zone)
	player.set_sprite_frames(GameState.hero.world_visual)
	if _pending_entraince_id != "":
		place_player_at_entrance(_pending_entraince_id)
	else:
		GameState.set_player_location(_get_screen_name(), "")
	add_child(WORLD_HUD.instantiate())
	_on_location_ready()

# Override in subclasses for extra setup (e.g. spawn points, extra signals)
func _on_location_ready() -> void:
	pass

# Override to provide the correct ScreenName for set_player_location
func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.VALLEY

# Override to add extra zone signal connections (e.g. zone_locked in valley)
func _connect_zone(zone: TriggerZone) -> void:
	zone.zone_entered.connect(_on_zone_entered)

func _on_zone_entered(zone: TriggerZone) -> void:
	player.on_zone_entered(zone)

func place_player_at_entrance(entrance_id: String) -> void:
	GameState.set_player_location(_get_screen_name(), entrance_id)
	if not is_node_ready():
		_pending_entraince_id = entrance_id
		return
	for zone in get_tree().get_nodes_in_group("trigger_zone"):
		zone = zone as TriggerZone
		if zone == null:
			continue
		if entrance_id == zone.entrance_id:
			player.place_at_entrance(zone)
			return
	push_warning("Entrance not found: ", entrance_id)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not pause_window.is_visible():
		pause_window.popup_centered()
