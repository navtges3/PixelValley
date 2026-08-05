extends TestCase

const NPC_SCENE := preload("res://scenes/world/characters/npc_actor.tscn")
const DIRECTIONAL_ANIMATIONS: Array[StringName] = [
	&"idle_down",
	&"idle_left",
	&"idle_right",
	&"idle_up",
]
const NPC_RESOURCE_DIRECTORY := "res://resources/characters/npcs"
const NPC_ROSTER_PATH := "res://resources/characters/npcs/npc_roster.tres"
const EXPECTED_NPC_IDS: Array[StringName] = [
	&"alchemist",
	&"blacksmith",
	&"innkeeper",
	&"mara",
	&"nessa",
	&"oren",
	&"rowan",
]
const SERVICE_INTERIORS: Dictionary[String, StringName] = {
	"res://scenes/world/buildings/interior/inn_interior.tscn": &"inn",
	"res://scenes/world/buildings/interior/potion_shop_interior.tscn": &"potion_shop",
	"res://scenes/world/buildings/interior/weapon_shop_interior.tscn": &"weapon_shop",
}

var _dialogue_ids: Array[StringName] = []
var _dialogue_conversations: Array[DialogueConversation] = []
var _service_ids: Array[StringName] = []
var _requested_services: Array[StringName] = []
var _status_changes: Array[int] = []

func run_tests() -> int:
	_begin_test_run()
	_test_data_validation()
	_test_authored_resources()
	_test_dialogue_interaction()
	_test_service_interaction()
	_test_dialogue_takes_priority()
	_test_facing()
	_test_status_presentation()
	_test_static_actor_configuration()
	_test_service_interaction_offsets()
	return _finish_test_run("NPC actor tests")

func _test_data_validation() -> void:
	var data := NpcData.new()
	var errors := data.get_validation_errors()

	_expect_equal(errors.size(), 6, "empty NPC data reports every required field")
	_expect_packed_array_contains(
		errors,
		"NPC ID cannot be empty.",
		"empty NPC ID is rejected"
	)
	_expect_packed_array_contains(
		errors,
		"has no display name",
		"empty NPC display name is rejected"
	)
	_expect_packed_array_contains(
		errors,
		"has no documented role",
		"empty NPC role is rejected"
	)
	_expect_packed_array_contains(
		errors,
		"has no documented location",
		"empty NPC location is rejected"
	)
	_expect_packed_array_contains(
		errors,
		"has no world visual",
		"missing NPC world visual is rejected"
	)
	_expect_packed_array_contains(
		errors,
		"has neither dialogue nor a service",
		"NPCs require an interaction"
	)

	data.npc_id = &"valid_npc"
	data.display_name = "Valid NPC"
	data.role = "Test role"
	data.location_id = &"test_location"
	data.world_visual = _make_world_visual()
	data.service_id = &"test_service"
	_expect_true(
		data.get_validation_errors().is_empty(),
		"complete NPC data passes validation"
	)

func _test_authored_resources() -> void:
	var roster := load(NPC_ROSTER_PATH) as NpcRoster
	_expect_not_null(roster, "authored NPC roster loads")
	if roster == null:
		return
	_expect_true(
		roster.get_validation_errors().is_empty(),
		"authored NPC roster validates"
	)
	_expect_equal(
		roster.npcs.size(),
		EXPECTED_NPC_IDS.size(),
		"NPC roster contains every expected character"
	)

	var seen_ids: Dictionary[StringName, String] = {}
	for data: NpcData in roster.npcs:
		if data == null:
			continue
		_expect_true(
			data.npc_id in EXPECTED_NPC_IDS,
			"roster contains recognized stable ID: %s" % data.npc_id
		)
		_expect_true(
			data.get_validation_errors().is_empty(),
			"authored NPC resource is valid: %s" % data.npc_id
		)
		_expect_equal(
			seen_ids.has(data.npc_id),
			false,
			"authored NPC ID is unique: %s" % data.npc_id
		)
		seen_ids[data.npc_id] = data.resource_path

		for animation_name: StringName in DIRECTIONAL_ANIMATIONS:
			_expect_true(
				data.world_visual.has_animation(animation_name),
				"NPC '%s' has '%s'" % [data.npc_id, animation_name]
			)

	for expected_id: StringName in EXPECTED_NPC_IDS:
		_expect_true(
			seen_ids.has(expected_id),
			"NPC roster includes '%s'" % expected_id
		)

	for file_name: String in DirAccess.get_files_at(NPC_RESOURCE_DIRECTORY):
		if file_name == "npc_roster.tres" or file_name.get_extension() != "tres":
			continue
		var resource_path := "%s/%s" % [NPC_RESOURCE_DIRECTORY, file_name]
		var data := load(resource_path) as NpcData
		_expect_not_null(data, "NPC resource loads: %s" % resource_path)
		if data != null:
			_expect_true(
				seen_ids.has(data.npc_id),
				"NPC resource is registered in the roster: %s" % resource_path
			)

	var duplicate_roster := NpcRoster.new()
	duplicate_roster.npcs = [roster.npcs[0], roster.npcs[0]]
	_expect_packed_array_contains(
		duplicate_roster.get_validation_errors(),
		"Duplicate NPC ID",
		"NPC roster rejects duplicate stable IDs"
	)

func _test_dialogue_interaction() -> void:
	_reset_signal_captures()
	var conversation := DialogueConversation.new()
	conversation.conversation_id = &"dialogue_npc_test"
	var data := _make_data(&"dialogue_npc")
	data.dialogue = conversation
	var npc := _spawn_actor(data)
	npc.dialogue_requested.connect(_on_dialogue_requested)
	npc.service_requested.connect(_on_service_requested)

	npc.interact_area.interacted.emit()

	_expect_equal(
		_dialogue_ids,
		[&"dialogue_npc"],
		"dialogue NPC emits its stable ID"
	)
	_expect_equal(
		_dialogue_conversations,
		[conversation],
		"dialogue NPC emits its configured conversation"
	)
	_expect_true(
		_requested_services.is_empty(),
		"dialogue-only NPC does not request a service"
	)
	npc.free()

func _test_service_interaction() -> void:
	_reset_signal_captures()
	var data := _make_data(&"service_npc")
	data.service_id = &"test_service"
	var npc := _spawn_actor(data)
	npc.dialogue_requested.connect(_on_dialogue_requested)
	npc.service_requested.connect(_on_service_requested)

	npc.interact_area.interacted.emit()

	_expect_equal(
		_service_ids,
		[&"service_npc"],
		"service NPC emits its stable ID"
	)
	_expect_equal(
		_requested_services,
		[&"test_service"],
		"service NPC emits its configured service"
	)
	_expect_true(
		_dialogue_conversations.is_empty(),
		"service-only NPC does not request dialogue"
	)
	npc.free()

func _test_dialogue_takes_priority() -> void:
	_reset_signal_captures()
	var conversation := DialogueConversation.new()
	conversation.conversation_id = &"hybrid_npc_test"
	var data := _make_data(&"hybrid_npc")
	data.dialogue = conversation
	data.service_id = &"test_service"
	var npc := _spawn_actor(data)
	npc.dialogue_requested.connect(_on_dialogue_requested)
	npc.service_requested.connect(_on_service_requested)

	npc.interact_area.interacted.emit()

	_expect_equal(
		_dialogue_conversations,
		[conversation],
		"dialogue takes priority when an NPC also has a service"
	)
	_expect_true(
		_requested_services.is_empty(),
		"hybrid NPC does not open its service immediately"
	)
	npc.free()

func _test_facing() -> void:
	var data := _make_data(&"facing_npc")
	data.service_id = &"test_service"
	var npc := _spawn_actor(data)
	var expected: Dictionary[int, StringName] = {
		NpcActor.Facing.DOWN: &"idle_down",
		NpcActor.Facing.LEFT: &"idle_left",
		NpcActor.Facing.RIGHT: &"idle_right",
		NpcActor.Facing.UP: &"idle_up",
	}

	for direction: int in expected:
		npc.facing = direction as NpcActor.Facing
		_expect_equal(
			npc.animated_sprite.animation,
			expected[direction],
			"NPC facing selects '%s'" % expected[direction]
		)
	npc.free()

func _test_status_presentation() -> void:
	_reset_signal_captures()
	var data := _make_data(&"status_npc")
	data.service_id = &"test_service"
	var npc := _spawn_actor(data)
	npc.status_changed.connect(_on_status_changed)

	_expect_equal(
		npc.status_indicator.visible,
		false,
		"NPC status indicator starts hidden"
	)
	_expect_equal(
		npc.status_indicator.texture,
		null,
		"hidden NPC status indicator starts without a texture"
	)

	npc.set_status(NpcActor.Status.NEW_CONVERSATION)
	_expect_status(
		npc,
		"res://assets/characters/status_indicators/new_conversation.png",
		"new conversation status"
	)
	npc.set_status(NpcActor.Status.QUEST_AVAILABLE)
	_expect_status(
		npc,
		"res://assets/characters/status_indicators/quest_available.png",
		"quest available status"
	)
	npc.set_status(NpcActor.Status.QUEST_READY)
	_expect_status(
		npc,
		"res://assets/characters/status_indicators/quest_ready.png",
		"quest ready status"
	)
	npc.set_status(NpcActor.Status.QUEST_READY)
	npc.set_status(NpcActor.Status.NONE)

	_expect_equal(
		npc.status_indicator.visible,
		false,
		"NONE hides the NPC status indicator"
	)
	_expect_equal(
		_status_changes,
		[
			NpcActor.Status.NEW_CONVERSATION,
			NpcActor.Status.QUEST_AVAILABLE,
			NpcActor.Status.QUEST_READY,
			NpcActor.Status.NONE,
		],
		"status changes emit once per actual transition"
	)
	npc.free()

func _test_static_actor_configuration() -> void:
	var data := _make_data(&"static_npc")
	data.service_id = &"test_service"
	var offset := Vector2(3.0, 12.0)
	var npc := _spawn_actor(data, offset)

	_expect_equal(npc.is_processing(), false, "static NPC disables frame processing")
	_expect_equal(
		npc.is_physics_processing(),
		false,
		"static NPC disables physics processing"
	)
	_expect_equal(
		npc.interact_area.position,
		offset,
		"NPC applies its authored interaction offset"
	)
	_expect_true(npc.y_sort_enabled, "NPC actor enables Y-sort propagation")
	_expect_true(npc.is_in_group(&"npc"), "NPC actor belongs to the NPC group")

	npc.interact_area.set_enabled(false)
	_expect_equal(
		npc.interact_area.monitoring,
		false,
		"disabled interaction area stops monitoring"
	)
	_expect_equal(
		npc.interact_area.is_processing_unhandled_input(),
		false,
		"disabled interaction area stops handling input"
	)
	npc.free()

func _test_service_interaction_offsets() -> void:
	for path: String in SERVICE_INTERIORS:
		var packed_scene := load(path) as PackedScene
		_expect_not_null(packed_scene, "service interior loads: %s" % path)
		if packed_scene == null:
			continue

		var interior := packed_scene.instantiate()
		var npc := _find_npc_actor(interior)
		_expect_not_null(npc, "service interior contains an NPC: %s" % path)
		if npc != null:
			_expect_equal(
				npc.interaction_offset,
				Vector2(0.0, 16.0),
				"service NPC interaction reaches past its counter: %s" % path
			)
			_expect_equal(
				npc.data.service_id,
				SERVICE_INTERIORS[path],
				"service interior retains its expected service: %s" % path
			)
		interior.free()

func _make_data(npc_id: StringName) -> NpcData:
	var data := NpcData.new()
	data.npc_id = npc_id
	data.display_name = "Test NPC"
	data.role = "Test role"
	data.location_id = &"test_location"
	data.world_visual = _make_world_visual()
	return data

func _make_world_visual() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	var texture := load(
		"res://assets/characters/npcs/weapon_shopkeep.png"
	) as Texture2D
	for animation_name: StringName in DIRECTIONAL_ANIMATIONS:
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, false)
		frames.add_frame(animation_name, texture)
	return frames

func _spawn_actor(
	data: NpcData,
	interaction_offset: Vector2 = Vector2.ZERO
) -> NpcActor:
	var npc := NPC_SCENE.instantiate() as NpcActor
	npc.data = data
	npc.interaction_offset = interaction_offset
	add_child(npc)
	return npc

func _find_npc_actor(node: Node) -> NpcActor:
	if node is NpcActor:
		return node as NpcActor
	for child: Node in node.get_children():
		var result := _find_npc_actor(child)
		if result != null:
			return result
	return null

func _expect_status(
	npc: NpcActor,
	texture_path: String,
	message: String
) -> void:
	_expect_true(npc.status_indicator.visible, "%s is visible" % message)
	_expect_equal(
		npc.status_indicator.texture.resource_path,
		texture_path,
		"%s uses the expected icon" % message
	)

func _expect_packed_array_contains(
	values: PackedStringArray,
	expected: String,
	message: String
) -> void:
	for value: String in values:
		if value.contains(expected):
			return
	_expect_true(false, message)

func _reset_signal_captures() -> void:
	_dialogue_ids.clear()
	_dialogue_conversations.clear()
	_service_ids.clear()
	_requested_services.clear()
	_status_changes.clear()

func _on_dialogue_requested(
	npc_id: StringName,
	conversation: DialogueConversation
) -> void:
	_dialogue_ids.append(npc_id)
	_dialogue_conversations.append(conversation)

func _on_service_requested(
	npc_id: StringName,
	service_id: StringName
) -> void:
	_service_ids.append(npc_id)
	_requested_services.append(service_id)

func _on_status_changed(status: NpcActor.Status) -> void:
	_status_changes.append(status)
