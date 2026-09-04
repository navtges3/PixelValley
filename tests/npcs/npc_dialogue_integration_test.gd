extends TestCase

const NPC_SCENE := preload("res://scenes/world/characters/npc_actor.tscn")
const NPC_ROSTER: NpcRoster = preload("res://resources/characters/npcs/npc_roster.tres")
const TEST_SAVE_SLOT: int = 999994

var _dialogue_npc_ids: Array[StringName] = []
var _service_npc_ids: Array[StringName] = []

func run_tests() -> int:
	_begin_test_run()
	_prepare_game_state()
	_test_normal_service_and_quest_npcs()
	_test_indicator_lifecycle_and_late_manager_binding()
	_cleanup()
	return _finish_test_run("NPC dialogue integration tests")

func _test_normal_service_and_quest_npcs() -> void:
	_dialogue_npc_ids.clear()
	_service_npc_ids.clear()
	var normal_data := NPC_ROSTER.get_npc(&"rowan")
	var quest_giver_data := NPC_ROSTER.get_npc(&"mara")
	var service_data := NPC_ROSTER.get_npc(&"alchemist").duplicate() as NpcData
	service_data.npc_id = &"test_service_npc"
	service_data.dialogue_sequences.clear()
	service_data.quest_ids.clear()
	var normal := _spawn_actor(normal_data)
	var service := _spawn_actor(service_data)
	var quest_giver := _spawn_actor(quest_giver_data)
	for npc: NpcActor in [normal, service, quest_giver]:
		npc.dialogue_requested.connect(_on_dialogue_requested)
		npc.service_requested.connect(_on_service_requested)
	normal.interact_area.interacted.emit()
	service.interact_area.interacted.emit()
	quest_giver.interact_area.interacted.emit()
	_expect_equal(_dialogue_npc_ids, [&"rowan", &"mara"], "normal NPC and quest giver route to dialogue")
	_expect_equal(_service_npc_ids, [&"test_service_npc"], "service-only NPC routes directly to its service")
	normal.free()
	service.free()
	quest_giver.free()

func _test_indicator_lifecycle_and_late_manager_binding() -> void:
	var controller := NpcQuestDialogueController.new()
	controller.set_dialogue_state(GameState.dialogue_state)
	_expect_equal(controller.get_npc_status(&"mara"), NpcActor.Status.NONE, "controller is safe before late quest initialization")
	var manager := QuestManager.new()
	manager.reconnect_signals()
	GameState.set_quest_manager(manager)
	controller.set_quest_manager(manager)
	var quest := _make_quest()
	manager.offer_quest(quest)
	_expect_equal(controller.get_npc_status(&"mara"), NpcActor.Status.QUEST_AVAILABLE, "offered quest marks its source NPC")
	manager.accept_quest(quest)
	_expect_equal(controller.get_npc_status(&"blacksmith"), NpcActor.Status.NEW_CONVERSATION, "active talk objective marks its target NPC")
	manager.abandon_quest(quest)
	_expect_equal(controller.get_npc_status(&"mara"), NpcActor.Status.QUEST_AVAILABLE, "abandon returns the indicator to the source NPC")
	manager.accept_quest(quest)
	GameState.gameplay_event.emit(NpcInteractedEvent.new(&"blacksmith"))
	_expect_equal(controller.get_npc_status(&"mara"), NpcActor.Status.QUEST_READY, "ready quest marks its turn-in NPC")
	controller.handle_action(_make_action(&"turn_in_quest"), controller.build_context(&"mara", &"village"))
	_expect_equal(controller.get_npc_status(&"mara"), NpcActor.Status.NONE, "turn-in clears the ready indicator")
	controller.clear_quest_manager()
	controller.clear_dialogue_state()

func _prepare_game_state() -> void:
	GameState.reset_state()
	GameState.hero = HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	GameState.hero.name = "NPC Dialogue Integration Hero"
	GameState.village = Village.new()
	GameState.village.name = "NPC Dialogue Integration Village"
	GameState.village.inn = Inn.new()
	GameState.village.potion_shop = Shop.new()
	GameState.village.weapon_shop = Shop.new()
	WorldManager.reset()
	SaveManager.save_slot = TEST_SAVE_SLOT

func _cleanup() -> void:
	GameState.reset_state()
	if SaveManager.has_save_data(TEST_SAVE_SLOT):
		SaveManager.delete_slot(TEST_SAVE_SLOT)

func _make_quest() -> Quest:
	var objective := TalkToNpcQuestObjective.new()
	objective.target_npc_id = &"blacksmith"
	var quest := Quest.new()
	quest.id = 800
	quest.title = "Indicator Integration Test"
	quest.category = Quest.Category.SIDE
	quest.source_type = Quest.SourceType.NPC
	quest.source_id = "mara"
	quest.turn_in_npc_id = "mara"
	quest.objectives.append(objective)
	return quest

func _make_action(action_id: StringName) -> DialogueAction:
	var action := DialogueAction.new()
	action.action_id = action_id
	return action

func _spawn_actor(data: NpcData) -> NpcActor:
	var npc := NPC_SCENE.instantiate() as NpcActor
	npc.data = data
	add_child(npc)
	return npc

func _on_dialogue_requested(npc_id: StringName) -> void:
	_dialogue_npc_ids.append(npc_id)

func _on_service_requested(npc_id: StringName, _service_id: StringName) -> void:
	_service_npc_ids.append(npc_id)
