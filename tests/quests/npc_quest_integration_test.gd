extends TestCase

const TEST_SAVE_SLOT := 999996

func run_tests() -> int:
	_begin_test_run()
	_prepare_game_state()
	_test_objective_event_contracts_and_restoration()
	_test_dialogue_runner_action_bridge()
	_test_dialogue_lifecycle_actions()
	_test_locked_dialogue_context()
	_test_main_progression_context()
	_test_delivery_action()
	_test_authored_dialogues_validate()
	_test_authored_dialogue_rolls_into_follow_up_quest()
	_test_authored_side_quest_chain()
	_test_existing_save_discovers_side_quest_chain()
	_cleanup()
	return _finish_test_run("NPC quest integration tests")

func _prepare_game_state() -> void:
	GameState.reset_state()
	GameState.hero = HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	GameState.hero.name = "NPC Quest Test Hero"
	GameState.village = Village.new()
	GameState.village.name = "NPC Quest Test Village"
	GameState.village.inn = Inn.new()
	GameState.village.potion_shop = Shop.new()
	GameState.village.weapon_shop = Shop.new()
	GameState.player_location = {
		"scene": ScreenManager.ScreenName.VILLAGE,
		"entrance_id": "",
	}
	WorldManager.reset()
	SaveManager.save_slot = TEST_SAVE_SLOT

func _test_objective_event_contracts_and_restoration() -> void:
	var talk := TalkToNpcQuestObjective.new()
	talk.target_npc_id = &"blacksmith"
	_expect_true(
		not talk.apply_event(NpcInteractedEvent.new(&"alchemist")),
		"talk objective ignores an unrelated NPC"
	)
	_expect_true(
		talk.apply_event(NpcInteractedEvent.new(&"blacksmith")),
		"talk objective accepts its stable target NPC ID"
	)
	_expect_true(
		not talk.apply_event(NpcInteractedEvent.new(&"blacksmith")),
		"completed talk objective ignores duplicate interactions"
	)
	var restored_talk := QuestObjectiveFactory.from_save_data(
		talk.get_save_data()
	) as TalkToNpcQuestObjective
	_expect_not_null(restored_talk, "factory restores talk objectives")
	if restored_talk != null:
		_expect_equal(
			restored_talk.target_npc_id,
			&"blacksmith",
			"talk objective restoration preserves the target NPC"
		)
		_expect_true(
			restored_talk.completed,
			"talk objective restoration preserves completion"
		)

	var delivery := DeliveryQuestObjective.new()
	delivery.target_npc_id = &"alchemist"
	delivery.item_id = "lesser_healing_potion"
	delivery.target_amount = 3
	_expect_true(
		not delivery.apply_event(
			ItemDeliveredEvent.new(
				&"blacksmith",
				"lesser_healing_potion",
				1
			)
		),
		"delivery objective ignores the wrong NPC"
	)
	_expect_true(
		not delivery.apply_event(
			ItemDeliveredEvent.new(
				&"alchemist",
				"lesser_healing_potion",
				0
			)
		),
		"delivery objective rejects non-positive amounts"
	)
	_expect_true(
		delivery.apply_event(
			ItemDeliveredEvent.new(
				&"alchemist",
				"lesser_healing_potion",
				2
			)
		),
		"delivery objective accepts matching delivery events"
	)
	var restored_delivery := QuestObjectiveFactory.from_save_data(
		delivery.get_save_data()
	) as DeliveryQuestObjective
	_expect_not_null(restored_delivery, "factory restores delivery objectives")
	if restored_delivery != null:
		_expect_equal(
			restored_delivery.current_amount,
			2,
			"delivery objective restoration preserves partial progress"
		)
		_expect_equal(
			restored_delivery.target_amount,
			3,
			"delivery objective restoration preserves its target"
		)

func _test_dialogue_lifecycle_actions() -> void:
	var manager := _make_manager()
	var controller := NpcQuestDialogueController.new()
	controller.set_quest_manager(manager)
	var quest := _make_npc_talk_quest(401, &"mara")
	quest.reward.gold = 25
	manager.offer_quest(quest)

	var context := controller.build_context(&"mara", &"village")
	_expect_equal(
		context[&"quest_state"],
		&"offered",
		"offered NPC quest routes to offered dialogue"
	)
	_expect_equal(
		controller.get_npc_status(&"mara"),
		NpcActor.Status.QUEST_AVAILABLE,
		"offered NPC quest displays the available indicator"
	)

	controller.handle_action(_make_action(&"decline_quest"), context)
	_expect_true(
		manager.is_quest_offered(quest.id),
		"declining leaves the quest offered"
	)
	_expect_equal(
		controller.build_context(&"mara", &"village")[&"quest_state"],
		&"offered",
		"declined quest is offered again on the next interaction"
	)

	controller.handle_action(_make_action(&"accept_quest"), context)
	_expect_true(manager.is_quest_active(quest.id), "dialogue accepts an offered quest")
	_expect_equal(
		controller.build_context(&"mara", &"village")[&"quest_state"],
		&"active",
		"accepted quest routes to active dialogue"
	)
	controller.handle_action(_make_action(&"accept_quest"), context)
	_expect_equal(
		manager.get_active_quests().size(),
		1,
		"repeated accept action does not duplicate an active quest"
	)

	GameState.gameplay_event.emit(NpcInteractedEvent.new(&"blacksmith"))
	_expect_true(
		manager.is_quest_active(quest.id),
		"unrelated NPC interaction does not complete the objective"
	)
	GameState.gameplay_event.emit(NpcInteractedEvent.new(&"mara"))
	_expect_true(manager.is_quest_ready(quest.id), "matching NPC interaction readies the quest")
	_expect_equal(
		controller.build_context(&"mara", &"village")[&"quest_state"],
		&"ready",
		"ready quest routes to turn-in dialogue"
	)
	_expect_equal(
		controller.get_npc_status(&"mara"),
		NpcActor.Status.QUEST_READY,
		"ready NPC quest displays the ready indicator"
	)

	var starting_gold := GameState.hero.inventory.gold
	var ready_context := controller.build_context(&"mara", &"village")
	var rewards := controller.handle_action(
		_make_action(&"turn_in_quest"),
		ready_context
	)
	_expect_equal(rewards.size(), 1, "turn-in returns the centralized reward result")
	_expect_true(manager.is_quest_completed(quest.id), "dialogue turn-in completes the quest")
	_expect_equal(
		GameState.hero.inventory.gold,
		starting_gold + 25,
		"dialogue turn-in grants the reward once"
	)
	_expect_equal(
		controller.build_context(&"mara", &"village")[&"quest_state"],
		&"completed",
		"turned-in quest routes to completed dialogue"
	)
	var repeated_rewards := controller.handle_action(
		_make_action(&"turn_in_quest"),
		ready_context
	)
	_expect_true(repeated_rewards.is_empty(), "duplicate turn-in returns no rewards")
	_expect_equal(
		GameState.hero.inventory.gold,
		starting_gold + 25,
		"duplicate turn-in cannot grant the reward twice"
	)
	controller.clear_quest_manager()

func _test_dialogue_runner_action_bridge() -> void:
	var manager := _make_manager()
	var controller := NpcQuestDialogueController.new()
	controller.set_quest_manager(manager)
	var quest := _make_npc_talk_quest(400, &"mara")
	manager.offer_quest(quest)

	var entry := DialogueEntry.new()
	entry.entry_id = &"offer"
	entry.pages = ["Will you help?"]
	var response := DialogueResponse.new()
	response.text = "I will help."
	response.actions.append(_make_action(&"accept_quest"))
	entry.responses.append(response)
	var sequence := DialogueSequence.new()
	sequence.sequence_id = &"npc_quest_action_test"
	sequence.start_entry_id = entry.entry_id
	sequence.entries.append(entry)
	var runner := DialogueRunner.new()
	runner.action_requested.connect(controller.handle_action)
	var context := controller.build_context(&"mara", &"village")

	_expect_true(
		runner.start_sequence(sequence, context),
		"state-aware NPC quest sequence starts"
	)
	runner.advance()
	runner.choose_response(0)
	_expect_true(
		manager.is_quest_active(quest.id),
		"DialogueRunner action reaches the NPC quest controller"
	)
	controller.clear_quest_manager()

func _test_locked_dialogue_context() -> void:
	var manager := _make_manager()
	var controller := NpcQuestDialogueController.new()
	controller.set_quest_manager(manager)
	var quest := _make_npc_talk_quest(402, &"blacksmith")
	manager.locked_quests.append(quest)
	var context := controller.build_context(&"blacksmith", &"village")
	_expect_equal(
		context[&"quest_state"],
		&"locked",
		"locked NPC quest routes to unavailable dialogue"
	)
	_expect_equal(
		controller.get_npc_status(&"blacksmith"),
		NpcActor.Status.NONE,
		"locked NPC quest displays no quest indicator"
	)
	controller.clear_quest_manager()

func _test_main_progression_context() -> void:
	var manager := _make_manager()
	var controller := NpcQuestDialogueController.new()
	controller.set_quest_manager(manager)

	_expect_equal(
		controller.build_context(&"rowan", &"village")[&"main_progression"],
		&"goblin_threat",
		"early main progression reports the goblin threat"
	)

	var orc_quest := Quest.new()
	orc_quest.id = QuestManager.ORC_WAR_CAMP_START_ID
	orc_quest.title = "Orc progression test"
	manager.active_quests.append(orc_quest)
	_expect_equal(
		controller.build_context(&"rowan", &"village")[&"main_progression"],
		&"orc_threat",
		"reaching the first war-camp quest reports the orc threat"
	)

	var ogre_quest := Quest.new()
	ogre_quest.id = QuestManager.OGRE_CAVE_START_ID
	ogre_quest.title = "Ogre progression test"
	manager.active_quests.append(ogre_quest)
	_expect_equal(
		controller.build_context(&"rowan", &"village")[&"main_progression"],
		&"ogre_threat",
		"reaching the first cave quest reports the ogre threat"
	)

	var victory_quest := Quest.new()
	victory_quest.id = QuestManager.FINAL_QUEST_ID
	victory_quest.title = "Victory progression test"
	victory_quest.completed = true
	manager.completed_quests.append(victory_quest)
	_expect_equal(
		controller.build_context(&"rowan", &"village")[&"main_progression"],
		&"victory",
		"completing the final quest reports victory"
	)
	controller.clear_quest_manager()

func _test_delivery_action() -> void:
	var manager := _make_manager()
	var controller := NpcQuestDialogueController.new()
	controller.set_quest_manager(manager)
	var delivery := DeliveryQuestObjective.new()
	delivery.target_npc_id = &"alchemist"
	delivery.item_id = "lesser_healing_potion"
	delivery.target_amount = 2
	var quest := Quest.new()
	quest.id = 403
	quest.title = "Medicine Delivery"
	quest.category = Quest.Category.SIDE
	quest.source_type = Quest.SourceType.NPC
	quest.source_id = "mara"
	quest.objectives.append(delivery)
	manager.activate_quest(quest)
	GameState.hero.inventory.add_potion("lesser_healing_potion", 2)

	var context := controller.build_context(&"alchemist", &"village")
	_expect_true(
		context[&"has_delivery_items"],
		"delivery target context reports sufficient items"
	)
	controller.handle_action(_make_action(&"deliver_quest_items"), context)
	_expect_equal(
		GameState.hero.inventory.get_potion_count("lesser_healing_potion"),
		0,
		"delivery removes the required inventory atomically"
	)
	_expect_true(
		manager.is_quest_ready(quest.id),
		"delivery event progresses the active quest through QuestManager"
	)
	controller.handle_action(_make_action(&"deliver_quest_items"), context)
	_expect_equal(
		delivery.current_amount,
		2,
		"duplicate delivery action cannot progress a ready quest again"
	)
	controller.clear_quest_manager()

func _test_authored_dialogues_validate() -> void:
	var expected_actions: Dictionary[String, Array] = {
		"res://resources/dialogue/sequences/mara_1010.tres":
			[&"accept_quest", &"decline_quest"],
		"res://resources/dialogue/sequences/alchemist_1010.tres":
			[&"complete_npc_interaction", &"turn_in_quest", &"open_service"],
		"res://resources/dialogue/sequences/alchemist_1020.tres":
			[&"accept_quest", &"decline_quest", &"open_service"],
		"res://resources/dialogue/sequences/blacksmith_1020.tres":
			[&"complete_npc_interaction", &"turn_in_quest", &"open_service"],
		"res://resources/dialogue/sequences/blacksmith_1025.tres":
			[&"accept_quest", &"decline_quest", &"open_service", &"turn_in_quest"],
		"res://resources/dialogue/sequences/blacksmith_1030.tres":
			[&"accept_quest", &"decline_quest", &"open_service"],
		"res://resources/dialogue/sequences/innkeeper_1030.tres":
			[&"deliver_quest_items", &"turn_in_quest", &"open_service"],
		"res://resources/dialogue/sequences/rowan_default.tres": [],
		"res://resources/dialogue/sequences/nessa_default.tres": [],
		"res://resources/dialogue/sequences/oren_default.tres": [],
		"res://resources/dialogue/sequences/mara_default.tres": [],
		"res://resources/dialogue/sequences/alchemist_default.tres": [&"open_service"],
		"res://resources/dialogue/sequences/blacksmith_default.tres": [&"open_service"],
		"res://resources/dialogue/sequences/innkeeper_default.tres": [&"open_service"],
	}
	var runner := DialogueRunner.new()
	for path: String in expected_actions:
		var sequence := load(path) as DialogueSequence
		_expect_not_null(sequence, "authored dialogue sequence loads: %s" % path)
		if sequence == null:
			continue
		_expect_true(
			runner.get_sequence_validation_errors(sequence).is_empty(),
			"authored dialogue sequence validates: %s" % path
		)
		var action_ids := _get_dialogue_action_ids(sequence)
		for action_id: StringName in expected_actions[path]:
			_expect_true(
				action_id in action_ids,
				"authored dialogue exposes action '%s': %s"
					% [action_id, path]
			)

func _test_authored_dialogue_rolls_into_follow_up_quest() -> void:
	if GameState.quest_manager != null:
		GameState.quest_manager.disconnect_signals()
	var manager := QuestManager.new()
	manager.new_game()
	GameState.set_quest_manager(manager)
	var controller := NpcQuestDialogueController.new()
	controller.set_quest_manager(manager)
	controller.handle_action(
		_make_action(&"accept_quest"),
		controller.build_context(&"mara", &"village")
	)

	var first_sequence := load(
		"res://resources/dialogue/sequences/alchemist_1010.tres"
	) as DialogueSequence
	var runner := DialogueRunner.new()
	runner.action_requested.connect(
		_handle_refreshing_dialogue_action.bind(
			runner,
			controller,
			&"alchemist",
			&"potion_shop_interior"
		)
	)
	_expect_true(
		runner.start_sequence(
			first_sequence,
			controller.build_context(&"alchemist", &"potion_shop_interior")
		),
		"alchemist quest 1010 sequence starts while the quest is active"
	)

	runner.advance()
	_expect_true(
		manager.is_quest_ready(1010),
		"finishing the alchemist's first line completes the talk objective"
	)
	runner.advance()
	runner.advance()
	runner.choose_response(0)
	_expect_true(
		manager.is_quest_completed(1010),
		"quest 1010 turns in without closing the conversation"
	)
	_expect_true(
		runner.is_running(),
		"quest 1010 sequence remains open on its reward entry"
	)

	runner.abort()
	var follow_up_sequence := load(
		"res://resources/dialogue/sequences/alchemist_1020.tres"
	) as DialogueSequence
	_expect_true(
		runner.start_sequence(
			follow_up_sequence,
			controller.build_context(&"alchemist", &"potion_shop_interior")
		),
		"alchemist quest 1020 sequence starts after quest 1010 completes"
	)
	runner.advance()
	runner.advance()
	_expect_true(
		runner.is_running(),
		"follow-up quest sequence remains open for its offer response"
	)
	runner.choose_response(0)
	_expect_true(manager.is_quest_active(1020), "the follow-up quest is accepted")
	controller.clear_quest_manager()

func _handle_refreshing_dialogue_action(
	action: DialogueAction,
	context: Dictionary[StringName, Variant],
	runner: DialogueRunner,
	controller: NpcQuestDialogueController,
	npc_id: StringName,
	location_id: StringName
) -> void:
	controller.handle_action(action, context)
	runner.update_context(controller.build_context(npc_id, location_id))

func _test_authored_side_quest_chain() -> void:
	if GameState.quest_manager != null:
		GameState.quest_manager.disconnect_signals()
	var manager := QuestManager.new()
	manager.new_game()
	GameState.set_quest_manager(manager)
	var controller := NpcQuestDialogueController.new()
	controller.set_quest_manager(manager)
	var starting_gold := GameState.hero.inventory.gold
	var starting_potion_count := GameState.hero.inventory.get_potion_count(
		"lesser_healing_potion"
	)
	var starting_weapon_count := GameState.hero.inventory.weapon_stash.size()

	var quest_1010 := manager.get_quest_by_id(1010)
	var quest_1020 := manager.get_quest_by_id(1020)
	var quest_1030 := manager.get_quest_by_id(1030)
	_expect_true(manager.is_quest_offered(1010), "first authored side quest starts offered")
	_expect_true(manager.get_quest_state(1020) == QuestManager.LifecycleState.LOCKED, "second side quest starts locked")
	_expect_true(manager.get_quest_state(1030) == QuestManager.LifecycleState.LOCKED, "third side quest starts locked")

	var villager_context := controller.build_context(&"mara", &"village")
	controller.handle_action(_make_action(&"accept_quest"), villager_context)
	GameState.gameplay_event.emit(NpcInteractedEvent.new(&"alchemist"))
	_expect_true(manager.is_quest_ready(1010), "talking to the alchemist readies quest 1010")
	var alchemist_turn_in := controller.build_context(&"alchemist", &"potion_shop_interior")
	controller.handle_action(_make_action(&"turn_in_quest"), alchemist_turn_in)
	_expect_true(manager.is_quest_completed(1010), "alchemist completes quest 1010")
	_expect_equal(
		GameState.hero.inventory.get_potion_count("lesser_healing_potion"),
		starting_potion_count + 1,
		"alchemist grants the potion reward"
	)
	_expect_true(manager.is_quest_offered(1020), "quest 1010 unlocks the alchemist's quest")

	var alchemist_offer := controller.build_context(&"alchemist", &"potion_shop_interior")
	controller.handle_action(_make_action(&"accept_quest"), alchemist_offer)
	GameState.gameplay_event.emit(NpcInteractedEvent.new(&"blacksmith"))
	_expect_true(manager.is_quest_ready(1020), "talking to the blacksmith readies quest 1020")
	var blacksmith_turn_in := controller.build_context(&"blacksmith", &"weapon_shop_interior")
	controller.handle_action(_make_action(&"turn_in_quest"), blacksmith_turn_in)
	_expect_true(manager.is_quest_completed(1020), "blacksmith completes quest 1020")
	_expect_equal(
		GameState.hero.inventory.weapon_stash.size(),
		starting_weapon_count + 1,
		"blacksmith grants a class-appropriate weapon"
	)
	_expect_equal(
		GameState.hero.inventory.get_quest_item_count("inn_key"),
		0,
		"quest 1020 does not grant the brass inn key directly"
	)
	_expect_true(manager.is_quest_offered(1025), "quest 1020 unlocks the smith's request")

	# Quest 1025: deliver wood_bundle x5 to blacksmith to obtain the inn key.
	var quest_1025 := manager.get_quest_by_id(1025)
	var blacksmith_offer_1025 := controller.build_context(&"blacksmith", &"weapon_shop_interior")
	controller.handle_action(_make_action(&"accept_quest"), blacksmith_offer_1025)
	_expect_true(manager.is_quest_active(1025), "quest 1025 accepted from blacksmith")
	GameState.hero.inventory.add_quest_item("wood_bundle", 5)
	var blacksmith_delivery := controller.build_context(&"blacksmith", &"weapon_shop_interior")
	_expect_true(
		bool(blacksmith_delivery[&"has_delivery_items"]),
		"blacksmith context detects the wood bundle delivery items"
	)
	controller.handle_action(_make_action(&"deliver_quest_items"), blacksmith_delivery)
	_expect_equal(
		GameState.hero.inventory.get_quest_item_count("wood_bundle"),
		0,
		"delivering the wood bundle removes it from inventory"
	)
	_expect_true(manager.is_quest_ready(1025), "wood bundle delivery readies quest 1025")
	var blacksmith_turn_in_1025 := controller.build_context(&"blacksmith", &"weapon_shop_interior")
	controller.handle_action(_make_action(&"turn_in_quest"), blacksmith_turn_in_1025)
	_expect_true(manager.is_quest_completed(1025), "blacksmith completes quest 1025")
	_expect_equal(
		GameState.hero.inventory.weapon_stash.size(),
		starting_weapon_count + 2,
		"blacksmith quest 1025 grants a second weapon"
	)
	_expect_equal(
		GameState.hero.inventory.get_quest_item_count("inn_key"),
		1,
		"blacksmith quest 1025 grants the brass inn key"
	)
	_expect_true(manager.is_quest_offered(1030), "quest 1025 unlocks the delivery quest")

	var blacksmith_offer_1030 := controller.build_context(&"blacksmith", &"weapon_shop_interior")
	controller.handle_action(_make_action(&"accept_quest"), blacksmith_offer_1030)
	var innkeeper_delivery := controller.build_context(&"innkeeper", &"inn_interior")
	_expect_true(
		bool(innkeeper_delivery[&"has_delivery_items"]),
		"innkeeper dialogue detects the brass key"
	)
	controller.handle_action(_make_action(&"deliver_quest_items"), innkeeper_delivery)
	_expect_equal(
		GameState.hero.inventory.get_quest_item_count("inn_key"),
		0,
		"delivering the brass key removes it from inventory"
	)
	_expect_true(manager.is_quest_ready(1030), "key delivery readies quest 1030")
	var innkeeper_turn_in := controller.build_context(&"innkeeper", &"inn_interior")
	controller.handle_action(_make_action(&"turn_in_quest"), innkeeper_turn_in)
	_expect_true(manager.is_quest_completed(1030), "innkeeper completes the quest chain")
	_expect_equal(
		GameState.hero.inventory.gold,
		starting_gold + quest_1030.reward.gold,
		"innkeeper grants the authored gold reward"
	)
	_expect_not_null(quest_1010, "quest 1010 remains registered")
	_expect_not_null(quest_1020, "quest 1020 remains registered")
	_expect_not_null(quest_1025, "quest 1025 remains registered")
	controller.clear_quest_manager()

func _test_existing_save_discovers_side_quest_chain() -> void:
	var manager := QuestManager.new()
	var existing_quest := Quest.new()
	existing_quest.id = 9001
	manager.active_quests.append(existing_quest)
	manager.add_missing_defined_quests()

	_expect_true(
		manager.is_quest_offered(1010),
		"an existing save discovers the initially unlocked side quest"
	)
	_expect_true(
		manager.get_quest_state(1020) == QuestManager.LifecycleState.LOCKED,
		"an existing save registers the locked follow-up quest"
	)
	_expect_true(
		manager.get_quest_by_id(9001) == existing_quest,
		"merging new definitions preserves existing quest instances"
	)

func _make_manager() -> QuestManager:
	if GameState.quest_manager != null:
		GameState.quest_manager.disconnect_signals()
	var manager := QuestManager.new()
	manager.reconnect_signals()
	GameState.set_quest_manager(manager)
	return manager

func _make_npc_talk_quest(quest_id: int, npc_id: StringName) -> Quest:
	var objective := TalkToNpcQuestObjective.new()
	objective.target_npc_id = npc_id
	var quest := Quest.new()
	quest.id = quest_id
	quest.title = "NPC Quest %d" % quest_id
	quest.category = Quest.Category.SIDE
	quest.source_type = Quest.SourceType.NPC
	quest.source_id = String(npc_id)
	quest.objectives.append(objective)
	return quest

func _make_action(action_id: StringName) -> DialogueAction:
	var action := DialogueAction.new()
	action.action_id = action_id
	return action

func _get_dialogue_action_ids(
	sequence: DialogueSequence
) -> Array[StringName]:
	var result: Array[StringName] = []
	for entry: DialogueEntry in sequence.entries:
		for action: DialogueAction in entry.actions:
			if action.action_id not in result:
				result.append(action.action_id)
		for response: DialogueResponse in entry.responses:
			for action: DialogueAction in response.actions:
				if action.action_id not in result:
					result.append(action.action_id)
	return result

func _cleanup() -> void:
	GameState.reset_state()
	if SaveManager.has_save_data(TEST_SAVE_SLOT):
		SaveManager.delete_slot(TEST_SAVE_SLOT)
