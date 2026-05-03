extends Node2D
class_name BaseLocation

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
		
	var world_hud := ScreenManager.get_world_hud() as WorldHUD
	if world_hud != null:
		world_hud.game_hud.hud_closed.connect(_on_hud_closed)
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
	var world_hud := ScreenManager.get_world_hud() as WorldHUD
	if world_hud == null:
		return
	var game_hud: GameHUD = world_hud.game_hud
	if event.is_action_pressed("ui_cancel"):
		if game_hud.is_open():
			_close_hud(game_hud)
		else:
			_open_hud(game_hud, GameHUD.Tab.SYSTEM)
	elif event.is_action_pressed("open_hud"):
		if game_hud.is_open():
			_close_hud(game_hud)
		else:
			_open_hud(game_hud)

func _open_hud(game_hud: GameHUD, tab: GameHUD.Tab = GameHUD.Tab.STATS) -> void:
	player.movement_blocked = true
	game_hud.show_hud(tab)

func _close_hud(game_hud: GameHUD) -> void:
	game_hud.hide_hud()
	player.movement_blocked = false

func _on_hud_closed() -> void:
	player.movement_blocked = false
