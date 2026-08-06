extends Node2D
class_name BaseLocation

@onready var y_sorted_world: Node2D = $YSortedWorld
@onready var player: Player = $YSortedWorld/Player

var _pending_entrance_id: String = ""
var _movement_blocked_before_dialogue: bool = false
var _active_dialogue_npc_id: StringName = &""
var _pending_service_npc_id: StringName = &""
var _pending_service_id: StringName = &""
var _npcs_by_id: Dictionary[StringName, NpcActor] = {}
var _npc_quest_controller: NpcQuestDialogueController = NpcQuestDialogueController.new()

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
		world_hud.dialogue_action_requested.connect(_on_dialogue_action_requested)
	_npc_quest_controller.state_changed.connect(_refresh_npc_quest_statuses)
	_npc_quest_controller.set_dialogue_state(GameState.dialogue_state)
	GameState.quest_manager_changed.connect(_on_quest_manager_changed)
	_npc_quest_controller.set_quest_manager(GameState.quest_manager)
	_bind_npcs()
	_refresh_npc_quest_statuses()
	_on_location_ready()

func _exit_tree() -> void:
	_npc_quest_controller.clear_quest_manager()
	_npc_quest_controller.clear_dialogue_state()
	if GameState.quest_manager_changed.is_connected(_on_quest_manager_changed):
		GameState.quest_manager_changed.disconnect(_on_quest_manager_changed)

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

func _on_dialogue_closed(reason: DialogueRunner.FinishReason) -> void:
	player.movement_blocked = _movement_blocked_before_dialogue
	if (
		reason == DialogueRunner.FinishReason.COMPLETED
		and not _active_dialogue_npc_id.is_empty()
	):
		GameState.gameplay_event.emit(
			NpcInteractedEvent.new(_active_dialogue_npc_id)
		)
	if (
		reason == DialogueRunner.FinishReason.COMPLETED
		and not _pending_service_id.is_empty()
	):
		_handle_npc_service_request(
			_pending_service_npc_id,
			_pending_service_id
		)
	_active_dialogue_npc_id = &""
	_pending_service_npc_id = &""
	_pending_service_id = &""

func _bind_npcs() -> void:
	var seen_ids: Dictionary[StringName, NpcActor] = {}
	_npcs_by_id.clear()
	for node: Node in get_tree().get_nodes_in_group(&"npc"):
		if not is_ancestor_of(node):
			continue
		var npc := node as NpcActor
		if npc == null or npc.data == null:
			continue
		var npc_id := npc.data.npc_id
		if npc_id.is_empty():
			push_error("NPC at '%s' has an empty ID." % npc.get_path())
			continue
		if seen_ids.has(npc_id):
			push_error("Duplicate NPC ID '%s' at '%s' and '%s'." % [npc_id, seen_ids[npc_id].get_path(), npc.get_path()])
			continue
		seen_ids[npc_id] = npc
		_npcs_by_id[npc_id] = npc
		npc.dialogue_requested.connect(_on_npc_dialogue_requested)
		npc.service_requested.connect(_on_npc_service_requested)

func _on_npc_dialogue_requested(npc_id: StringName, conversation: DialogueConversation) -> void:
	var npc: NpcActor = _npcs_by_id.get(npc_id)
	if npc == null:
		push_warning("Dialogue requested for unknown NPC '%s'." % npc_id)
		return
	if conversation == null:
		push_warning("NPC '%s' requested null dialogue." % npc_id)
		return
	if npc.data == null or npc.data.dialogue != conversation:
		push_warning(
			"NPC '%s' requested an unregistered conversation." % npc_id
		)
		return
	var world_hud := ScreenManager.get_world_hud() as WorldHUD
	if world_hud == null:
		push_warning("Dialogue requested without an available WorldHUD.")
		return
	var context := _npc_quest_controller.build_context(npc_id, _get_dialogue_location_id())
	if world_hud.start_dialogue(conversation, context):
		_active_dialogue_npc_id = npc_id

func _on_dialogue_action_requested(action: DialogueAction, context: Dictionary[StringName, Variant]) -> void:
	if action.action_id == &"open_service":
		_queue_dialogue_service(context)
		return
	var rewards := _npc_quest_controller.handle_action(action, context)
	var world_hud := ScreenManager.get_world_hud() as WorldHUD
	if world_hud == null:
		return
	var npc_id := StringName(context.get(&"npc_id", &""))
	world_hud.update_dialogue_context(
		_npc_quest_controller.build_context(
			npc_id,
			_get_dialogue_location_id()
		)
	)
	if not rewards.is_empty():
		world_hud.queue_quest_rewards(rewards)

func _queue_dialogue_service(
	context: Dictionary[StringName, Variant]
) -> void:
	var npc_id := StringName(context.get(&"npc_id", &""))
	var npc: NpcActor = _npcs_by_id.get(npc_id)
	if npc == null or npc.data == null or npc.data.service_id.is_empty():
		push_warning("NPC '%s' has no service to open." % npc_id)
		return
	_pending_service_npc_id = npc_id
	_pending_service_id = npc.data.service_id

func _on_quest_manager_changed(manager: QuestManager) -> void:
	_npc_quest_controller.set_quest_manager(manager)

func _refresh_npc_quest_statuses() -> void:
	for npc_id: StringName in _npcs_by_id:
		var npc: NpcActor = _npcs_by_id[npc_id]
		npc.set_status(_npc_quest_controller.get_npc_status(npc_id))

func _on_npc_service_requested(npc_id: StringName, service_id: StringName) -> void:
	_handle_npc_service_request(npc_id, service_id)

func _handle_npc_service_request(npc_id: StringName, service_id: StringName) -> void:
	push_warning("NPC '%s' requested unsupported service '%s'." % [npc_id, service_id])

func _get_dialogue_location_id() -> StringName:
	return StringName(name.to_snake_case())
