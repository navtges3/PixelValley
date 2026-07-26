extends TestCase

const TEST_SAVE_SLOT := 999996

func run_tests() -> int:
	_begin_test_run()
	_prepare_game_state()
	_test_objective_event_contracts_and_restoration()
	_test_dialogue_runner_action_bridge()
	_test_dialogue_lifecycle_actions()
	_test_locked_dialogue_context()
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
	var quest := _make_npc_talk_quest(401, &"test_villager")
	quest.reward.gold = 25
	manager.offer_quest(quest)

	var context := controller.build_context(&"test_villager", &"village")
	_expect_equal(
		context[&"quest_state"],
		&"offered",
		"offered NPC quest routes to offered dialogue"
	)
	_expect_equal(
		controller.get_npc_status(&"test_villager"),
		NpcActor.Status.QUEST_AVAILABLE,
		"offered NPC quest displays the available indicator"
	)

	controller.handle_action(_make_action(&"decline_quest"), context)
	_expect_true(
		manager.is_quest_offered(quest.id),
		"declining leaves the quest offered"
	)
	_expect_equal(
		controller.build_context(&"test_villager", &"village")[&"quest_state"],
		&"offered",
		"declined quest is offered again on the next interaction"
	)

	controller.handle_action(_make_action(&"accept_quest"), context)
	_expect_true(manager.is_quest_active(quest.id), "dialogue accepts an offered quest")
	_expect_equal(
		controller.build_context(&"test_villager", &"village")[&"quest_state"],
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
	GameState.gameplay_event.emit(NpcInteractedEvent.new(&"test_villager"))
	_expect_true(manager.is_quest_ready(quest.id), "matching NPC interaction readies the quest")
	_expect_equal(
		controller.build_context(&"test_villager", &"village")[&"quest_state"],
		&"ready",
		"ready quest routes to turn-in dialogue"
	)
	_expect_equal(
		controller.get_npc_status(&"test_villager"),
		NpcActor.Status.QUEST_READY,
		"ready NPC quest displays the ready indicator"
	)

	var starting_gold := GameState.hero.inventory.gold
	var ready_context := controller.build_context(&"test_villager", &"village")
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
		controller.build_context(&"test_villager", &"village")[&"quest_state"],
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
	var quest := _make_npc_talk_quest(400, &"test_villager")
	manager.offer_quest(quest)

	var entry := DialogueEntry.new()
	entry.entry_id = &"offer"
	entry.pages = ["Will you help?"]
	var response := DialogueResponse.new()
	response.text = "I will help."
	response.actions.append(_make_action(&"accept_quest"))
	entry.responses.append(response)
	var conversation := DialogueConversation.new()
	conversation.conversation_id = &"npc_quest_action_test"
	conversation.start_entry_id = entry.entry_id
	conversation.entries.append(entry)
	var runner := DialogueRunner.new()
	runner.action_requested.connect(controller.handle_action)
	var context := controller.build_context(&"test_villager", &"village")

	_expect_true(
		runner.start(conversation, context),
		"state-aware NPC quest conversation starts"
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
	quest.source_id = "test_villager"
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
		"res://resources/dialogue/quests/test_villager_quest_conversation.tres":
			[&"accept_quest", &"decline_quest"],
		"res://resources/dialogue/quests/alchemist_quest_conversation.tres":
			[
				&"complete_npc_interaction",
				&"turn_in_quest",
				&"accept_quest",
				&"decline_quest",
				&"open_service",
			],
		"res://resources/dialogue/quests/blacksmith_quest_conversation.tres":
			[
				&"complete_npc_interaction",
				&"turn_in_quest",
				&"accept_quest",
				&"decline_quest",
				&"open_service",
			],
		"res://resources/dialogue/quests/innkeeper_quest_conversation.tres":
			[&"deliver_quest_items", &"turn_in_quest", &"open_service"],
	}
	var runner := DialogueRunner.new()
	for path: String in expected_actions:
		var conversation := load(path) as DialogueConversation
		_expect_not_null(conversation, "authored quest dialogue loads: %s" % path)
		if conversation == null:
			continue
		_expect_true(
			runner.get_validation_errors(conversation).is_empty(),
			"authored quest dialogue validates: %s" % path
		)
		var action_ids := _get_dialogue_action_ids(conversation)
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
		controller.build_context(&"test_villager", &"village")
	)

	var conversation := load(
		"res://resources/dialogue/quests/alchemist_quest_conversation.tres"
	) as DialogueConversation
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
		runner.start(
			conversation,
			controller.build_context(&"alchemist", &"potion_shop_interior")
		),
		"alchemist quest conversation starts while quest 11 is active"
	)

	runner.advance()
	_expect_true(
		manager.is_quest_ready(11),
		"finishing the alchemist's first line completes the talk objective"
	)
	runner.advance()
	runner.advance()
	runner.choose_response(0)
	_expect_true(
		manager.is_quest_completed(11),
		"quest 11 turns in without closing the conversation"
	)
	_expect_true(
		runner.is_running(),
		"dialogue remains open after the quest 11 reward"
	)

	runner.advance()
	runner.advance()
	runner.advance()
	runner.choose_response(0)
	_expect_true(
		manager.is_quest_active(12),
		"the follow-up quest is accepted in the same conversation"
	)
	runner.advance()
	_expect_true(
		not runner.is_running(),
		"conversation closes only after the follow-up response"
	)
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

	var quest_11 := manager.get_quest_by_id(11)
	var quest_12 := manager.get_quest_by_id(12)
	var quest_13 := manager.get_quest_by_id(13)
	_expect_true(manager.is_quest_offered(11), "first authored side quest starts offered")
	_expect_true(manager.get_quest_state(12) == QuestManager.LifecycleState.LOCKED, "second side quest starts locked")
	_expect_true(manager.get_quest_state(13) == QuestManager.LifecycleState.LOCKED, "third side quest starts locked")

	var villager_context := controller.build_context(&"test_villager", &"village")
	controller.handle_action(_make_action(&"accept_quest"), villager_context)
	GameState.gameplay_event.emit(NpcInteractedEvent.new(&"alchemist"))
	_expect_true(manager.is_quest_ready(11), "talking to the alchemist readies quest 11")
	var alchemist_turn_in := controller.build_context(&"alchemist", &"potion_shop_interior")
	controller.handle_action(_make_action(&"turn_in_quest"), alchemist_turn_in)
	_expect_true(manager.is_quest_completed(11), "alchemist completes quest 11")
	_expect_equal(
		GameState.hero.inventory.get_potion_count("lesser_healing_potion"),
		starting_potion_count + 1,
		"alchemist grants the potion reward"
	)
	_expect_true(manager.is_quest_offered(12), "quest 11 unlocks the alchemist's quest")

	var alchemist_offer := controller.build_context(&"alchemist", &"potion_shop_interior")
	controller.handle_action(_make_action(&"accept_quest"), alchemist_offer)
	GameState.gameplay_event.emit(NpcInteractedEvent.new(&"blacksmith"))
	_expect_true(manager.is_quest_ready(12), "talking to the blacksmith readies quest 12")
	var blacksmith_turn_in := controller.build_context(&"blacksmith", &"weapon_shop_interior")
	controller.handle_action(_make_action(&"turn_in_quest"), blacksmith_turn_in)
	_expect_true(manager.is_quest_completed(12), "blacksmith completes quest 12")
	_expect_equal(
		GameState.hero.inventory.weapon_stash.size(),
		starting_weapon_count + 1,
		"blacksmith grants a class-appropriate weapon"
	)
	_expect_equal(
		GameState.hero.inventory.get_quest_item_count("inn_key"),
		1,
		"blacksmith grants the brass inn key"
	)
	_expect_true(manager.is_quest_offered(13), "quest 12 unlocks the delivery quest")

	var blacksmith_offer := controller.build_context(&"blacksmith", &"weapon_shop_interior")
	controller.handle_action(_make_action(&"accept_quest"), blacksmith_offer)
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
	_expect_true(manager.is_quest_ready(13), "key delivery readies quest 13")
	var innkeeper_turn_in := controller.build_context(&"innkeeper", &"inn_interior")
	controller.handle_action(_make_action(&"turn_in_quest"), innkeeper_turn_in)
	_expect_true(manager.is_quest_completed(13), "innkeeper completes the quest chain")
	_expect_equal(
		GameState.hero.inventory.gold,
		starting_gold + quest_13.reward.gold,
		"innkeeper grants the authored gold reward"
	)
	_expect_not_null(quest_11, "quest 11 remains registered")
	_expect_not_null(quest_12, "quest 12 remains registered")
	controller.clear_quest_manager()

func _test_existing_save_discovers_side_quest_chain() -> void:
	var manager := QuestManager.new()
	var existing_quest := Quest.new()
	existing_quest.id = 1
	manager.active_quests.append(existing_quest)
	manager.add_missing_defined_quests()

	_expect_true(
		manager.is_quest_offered(11),
		"an existing save discovers the initially unlocked side quest"
	)
	_expect_true(
		manager.get_quest_state(12) == QuestManager.LifecycleState.LOCKED,
		"an existing save registers the locked follow-up quest"
	)
	_expect_true(
		manager.get_quest_by_id(1) == existing_quest,
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
	conversation: DialogueConversation
) -> Array[StringName]:
	var result: Array[StringName] = []
	for entry: DialogueEntry in conversation.entries:
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
