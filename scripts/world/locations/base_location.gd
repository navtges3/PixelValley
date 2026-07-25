extends Node2D
class_name BaseLocation

@onready var player: Player = $Player

var _pending_entrance_id: String = ""
var _movement_blocked_before_dialogue: bool = false

func _ready() -> void:
	player.set_sprite_frames(GameState.hero.world_visual)
	if _pending_entrance_id != "":
		place_player_at_entrance(_pending_entrance_id)
	else:
		GameState.set_player_location(_get_screen_name(), "")

	var world_hud := ScreenManager.get_world_hud() as WorldHUD
	if world_hud != null:
		world_hud.game_hud.hud_closed.connect(_on_hud_closed)
		world_hud.dialogue_opened.connect(_on_dialogue_opened)
		world_hud.dialogue_closed.connect(_on_dialogue_closed)
	_on_location_ready()

# Override in subclasses for extra setup (e.g. spawn points, extra signals)
func _on_location_ready() -> void:
	pass

# Override to provide the correct ScreenName for set_player_location
func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.VALLEY

func place_player_at_entrance(entrance_id: String) -> void:
	GameState.set_player_location(_get_screen_name(), entrance_id)
	if not is_node_ready():
		_pending_entrance_id = entrance_id
		return
	var candidates: Array[Node] = []
	candidates.append_array(get_tree().get_nodes_in_group("trigger_zone"))
	candidates.append_array(get_tree().get_nodes_in_group("building"))
	for candidate in candidates:
		if candidate.get("entrance_id") == entrance_id:
			player.place_at_entrance(candidate)
			return
	push_warning("Entrance not found: %s" % entrance_id)

func _is_window_close_input(event: InputEvent) -> bool:
	return event.is_action_pressed("open_hud") or event.is_action_pressed("ui_cancel")

func _handle_window_input(event: InputEvent, window: GameWindow) -> bool:
	if window == null or not window.is_visible_in_tree():
		return false
	if _is_window_close_input(event):
		window.close()
		get_viewport().set_input_as_handled()
	return true

func _input(event: InputEvent) -> void:
	var world_hud := ScreenManager.get_world_hud() as WorldHUD
	if world_hud == null:
		return
	if world_hud.is_dialogue_open():
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

func _on_dialogue_opened() -> void:
	_movement_blocked_before_dialogue = player.movement_blocked
	player.movement_blocked = true
	player.clear_prompt()

func _on_dialogue_closed(_reason: DialogueRunner.FinishReason) -> void:
	player.movement_blocked = _movement_blocked_before_dialogue
