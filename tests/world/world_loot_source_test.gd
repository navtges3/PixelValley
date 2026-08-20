extends TestCase

const TEST_LOOT_SOURCE := preload(
	"res://tests/world/test_world_loot_source.gd"
)
const INTERACT_AREA_SCENE := preload(
	"res://scenes/world/interact_area.tscn"
)
const WORLD_LOOT_SOURCE_SCENE := preload(
	"res://scenes/world/world_loot_source.tscn"
)
const WORLD_PICKUP_SCENE := preload(
	"res://scenes/world/world_pickup.tscn"
)
const WORLD_LOOT_CONTAINER_SCENE := preload(
	"res://scenes/world/world_loot_container.tscn"
)
const CHEST_SCENE := preload("res://scenes/world/chest.tscn")
const CRATE_SCENE := preload("res://scenes/world/crate.tscn")
const PLAYER_SCENE := preload("res://scenes/world/characters/player.tscn")

var _last_claim_result: WorldLootSource.ClaimResult
var _last_claim_rewards: Array[RewardEntry] = []
var _claim_signal_count: int = 0

func run_tests() -> int:
	_begin_test_run()
	_test_reusable_scene_has_interaction_component()
	_test_world_pickup_scene_uses_shared_interaction()
	_test_container_variants_use_context_prompts()
	_test_container_visual_state_and_reward_presentation()
	_test_claimed_container_restores_opened()
	_test_world_reward_movement_state_restores()
	_test_interaction_signal_grants_once()
	_test_claim_grants_loot_once()
	_test_claimed_pickup_hides_after_feedback()
	_test_claimed_state_restores_on_reentry()
	_test_claimed_pickup_restores_hidden()
	_test_inventory_and_world_state_round_trip()
	_test_legacy_world_state_uses_empty_claims()
	_test_empty_ids_are_rejected()
	_test_duplicate_ids_in_one_location_are_detected()
	_test_same_id_in_different_locations_is_allowed()
	return _finish_test_run("World loot source tests")

func _test_reusable_scene_has_interaction_component() -> void:
	var source := WORLD_LOOT_SOURCE_SCENE.instantiate() as WorldLootSource

	_expect_not_null(source, "the reusable world-loot scene instantiates")
	_expect_true(
		source.get_node_or_null("InteractArea") is InteractArea,
		"the reusable scene contains its interaction component"
	)
	source.free()

func _test_world_pickup_scene_uses_shared_interaction() -> void:
	var pickup := WORLD_PICKUP_SCENE.instantiate() as WorldPickup

	_expect_not_null(pickup, "the reusable world-pickup scene instantiates")
	_expect_true(
		pickup.get_node_or_null("InteractArea") is InteractArea,
		"the world pickup inherits the shared interaction component"
	)
	_expect_true(
		pickup.get_node_or_null("InteractArea/CollisionShape2D") is CollisionShape2D,
		"the world pickup inherits the shared interaction collision"
	)
	pickup.free()

func _test_container_variants_use_context_prompts() -> void:
	var chest := CHEST_SCENE.instantiate() as WorldLootContainer
	var crate := CRATE_SCENE.instantiate() as WorldLootContainer

	_expect_not_null(chest, "the reusable chest scene instantiates")
	_expect_equal(
		(chest.get_node("InteractArea") as InteractArea).prompt_label,
		"Open Chest",
		"closed chests use the context-correct interaction prompt"
	)
	_expect_equal(
		(crate.get_node("InteractArea") as InteractArea).prompt_label,
		"Search Crate",
		"closed crates use the context-correct interaction prompt"
	)
	chest.free()
	crate.free()

func _test_container_visual_state_and_reward_presentation() -> void:
	WorldManager.reset()
	var container := WORLD_LOOT_CONTAINER_SCENE.instantiate() as WorldLootContainer
	var closed_texture := GradientTexture1D.new()
	var opened_texture := GradientTexture1D.new()
	container.location_id = "forest"
	container.loot_source_id = "forest/presentation_chest"
	container.loot_table = _new_deterministic_table()
	container.closed_texture = closed_texture
	container.opened_texture = opened_texture
	add_child(container)

	_expect_equal(
		container.sprite.texture,
		closed_texture,
		"unclaimed containers display their authored closed visual"
	)
	var world_hud := ScreenManager.get_world_hud() as WorldHUD
	var hud_was_visible: bool = world_hud.visible
	world_hud.show()
	var presented_rewards: Array[RewardEntry] = [
		RewardEntry.gold(10),
		RewardEntry.potion("lesser_healing_potion", 2),
	]
	container.claim_finished.emit(
		WorldLootSource.ClaimResult.CLAIMED,
		presented_rewards
	)
	_expect_equal(
		container.sprite.texture,
		opened_texture,
		"successful claims immediately display the opened visual"
	)
	_expect_true(
		world_hud.reward_window.is_open(),
		"non-empty container rewards open the focused reward presentation"
	)
	_expect_equal(
		world_hud.reward_window.reward_list.get_child_count(),
		2,
		"the container reward presentation lists every granted reward"
	)
	world_hud.reward_window._handle_cancel()

	var empty_rewards: Array[RewardEntry] = []
	container.claim_finished.emit(WorldLootSource.ClaimResult.CLAIMED, empty_rewards)
	_expect_true(
		not world_hud.reward_window.is_open(),
		"empty container results do not open an empty reward presentation"
	)
	if not hud_was_visible:
		world_hud.hide()
	container.free()

func _test_claimed_container_restores_opened() -> void:
	WorldManager.reset()
	WorldManager.mark_loot_claimed("forest", "forest/restored_chest")
	var container := WORLD_LOOT_CONTAINER_SCENE.instantiate() as WorldLootContainer
	var opened_texture := GradientTexture1D.new()
	container.location_id = "forest"
	container.loot_source_id = "forest/restored_chest"
	container.loot_table = _new_deterministic_table()
	container.opened_texture = opened_texture
	add_child(container)

	_expect_equal(
		container.sprite.texture,
		opened_texture,
		"claimed containers restore their opened visual on scene entry"
	)
	_expect_true(
		not container.interact_area.monitoring,
		"restored opened containers cannot be claimed again"
	)
	container.free()

func _test_world_reward_movement_state_restores() -> void:
	var location := BaseLocation.new()
	var test_player := PLAYER_SCENE.instantiate() as Player
	var test_camera := test_player.get_node("Camera2D") as Camera2D
	test_camera.free()
	add_child(test_player)
	location.player = test_player

	test_player.movement_blocked = false
	location._on_world_rewards_opened()
	_expect_true(test_player.movement_blocked, "world rewards block player movement")
	location._on_world_rewards_closed()
	_expect_true(
		not test_player.movement_blocked,
		"closing world rewards restores an initially unblocked player"
	)

	test_player.movement_blocked = true
	location._on_world_rewards_opened()
	var focused_button := Button.new()
	add_child(focused_button)
	focused_button.grab_focus()
	location._on_world_rewards_closed()
	_expect_true(
		test_player.movement_blocked,
		"closing world rewards preserves a pre-existing movement block"
	)
	_expect_equal(
		get_viewport().gui_get_focus_owner(),
		null,
		"closing world rewards does not strand focus on a hidden control"
	)
	focused_button.free()
	test_player.free()
	location.free()

func _test_interaction_signal_grants_once() -> void:
	WorldManager.reset()
	var original_hero := GameState.hero
	var hero := _new_hero()
	GameState.hero = hero
	var source := _new_source("forest", "forest/interacted_pickup")

	source.interact_area.interacted.emit()
	source.interact_area.interacted.emit()

	_expect_equal(hero.inventory.gold, 10, "interaction grants authored gold once")
	_expect_equal(
		hero.inventory.get_potion_count("lesser_healing_potion"),
		2,
		"interaction grants authored items once"
	)
	_expect_true(
		not source.interact_area.monitoring,
		"interaction immediately disables the claimed source"
	)
	source.free()
	GameState.hero = original_hero

func _test_claim_grants_loot_once() -> void:
	WorldManager.reset()
	var hero := _new_hero()
	var source := _new_source("forest", "forest/test_chest")
	source.claim_finished.connect(_on_claim_finished)
	_reset_claim_signal()

	var first_result := source.try_claim(hero)

	_expect_equal(
		first_result,
		WorldLootSource.ClaimResult.CLAIMED,
		"an unclaimed source reports a successful claim"
	)
	_expect_equal(hero.inventory.gold, 10, "a claim grants authored gold")
	_expect_equal(
		hero.inventory.get_potion_count("lesser_healing_potion"),
		2,
		"a claim grants authored item quantities"
	)
	_expect_true(source.is_claimed(), "a successful claim records its stable ID")
	_expect_true(
		not source.interact_area.monitoring,
		"a successful claim disables interaction immediately"
	)
	_expect_equal(source.autosave_count, 1, "a successful claim requests one autosave")
	_expect_equal(_claim_signal_count, 1, "a successful claim emits one result signal")
	_expect_equal(
		_last_claim_result,
		WorldLootSource.ClaimResult.CLAIMED,
		"the result signal reports a successful claim"
	)
	_expect_equal(_last_claim_rewards.size(), 2, "the result signal includes granted rewards")

	var second_result := source.try_claim(hero)

	_expect_equal(
		second_result,
		WorldLootSource.ClaimResult.ALREADY_CLAIMED,
		"repeated interaction reports an existing claim"
	)
	_expect_equal(hero.inventory.gold, 10, "repeated interaction does not duplicate gold")
	_expect_equal(
		hero.inventory.get_potion_count("lesser_healing_potion"),
		2,
		"repeated interaction does not duplicate items"
	)
	_expect_equal(source.autosave_count, 1, "a duplicate interaction does not autosave")
	source.free()

func _test_claimed_pickup_hides_after_feedback() -> void:
	WorldManager.reset()
	var pickup := WORLD_PICKUP_SCENE.instantiate() as WorldPickup
	pickup.location_id = "forest"
	pickup.loot_source_id = "forest/feedback_pickup"
	pickup.loot_table = _new_deterministic_table()
	add_child(pickup)
	var rewards: Array[RewardEntry] = [RewardEntry.gold(10)]

	pickup.claim_finished.emit(WorldLootSource.ClaimResult.CLAIMED, rewards)

	_expect_true(
		not pickup.interact_area.monitoring,
		"a claimed pickup cannot receive another interaction"
	)
	_expect_true(
		not pickup.visuals.visible,
		"a claimed pickup disappears after collection feedback"
	)
	var world_hud := ScreenManager.get_world_hud() as WorldHUD
	if world_hud != null:
		world_hud.acquisition_notification.clear()
	pickup.free()

func _test_claimed_state_restores_on_reentry() -> void:
	WorldManager.reset()
	var hero := _new_hero()
	var first_source := _new_source("forest", "forest/reentry_chest")
	first_source.try_claim(hero)
	first_source.free()

	var restored_source := _new_source("forest", "forest/reentry_chest")

	_expect_true(restored_source.is_claimed(), "re-entering preserves the source claim")
	_expect_true(
		not restored_source.interact_area.monitoring,
		"a restored claimed source starts with interaction disabled"
	)
	restored_source.free()

func _test_claimed_pickup_restores_hidden() -> void:
	WorldManager.reset()
	WorldManager.mark_loot_claimed("forest", "forest/restored_pickup")
	var pickup := WORLD_PICKUP_SCENE.instantiate() as WorldPickup
	pickup.location_id = "forest"
	pickup.loot_source_id = "forest/restored_pickup"
	pickup.loot_table = _new_deterministic_table()
	add_child(pickup)

	_expect_true(pickup.is_claimed(), "the pickup restores its claimed state")
	_expect_true(
		not pickup.interact_area.monitoring,
		"a restored pickup cannot receive interaction"
	)
	_expect_true(
		not pickup.visuals.visible,
		"a restored claimed pickup remains absent"
	)
	pickup.free()

func _test_inventory_and_world_state_round_trip() -> void:
	WorldManager.reset()
	var hero := _new_hero()
	var source := _new_source("forest", "forest/saved_chest")
	source.try_claim(hero)
	var inventory_data := SaveManager._get_inventory_data(hero.inventory)
	var world_data := WorldManager.get_save_data()
	source.free()

	WorldManager.reset()
	var restored_inventory := SaveManager._load_inventory(inventory_data)
	WorldManager.load_save_data(world_data)

	_expect_equal(restored_inventory.gold, 10, "saved loot gold survives inventory loading")
	_expect_equal(
		restored_inventory.get_potion_count("lesser_healing_potion"),
		2,
		"saved loot items survive inventory loading"
	)
	_expect_true(
		WorldManager.is_loot_claimed("forest", "forest/saved_chest"),
		"saved world state preserves the loot claim"
	)

func _test_legacy_world_state_uses_empty_claims() -> void:
	WorldManager.load_save_data({
		"forest": {
			"unlocked": true,
			"defeated_spawners": ["ForestGoblin"],
		},
	})
	var saved_data := WorldManager.get_save_data()
	var forest: Dictionary = saved_data["forest"]

	_expect_true(not WorldManager.is_loot_claimed("forest", "forest/legacy_chest"), "legacy saves load loot sources as unclaimed")
	_expect_equal(forest["claimed_loot_ids"], [], "legacy locations receive an empty claimed-loot array")
	_expect_equal(forest["defeated_spawners"], ["ForestGoblin"], "legacy location state is otherwise preserved")

func _test_empty_ids_are_rejected() -> void:
	WorldManager.reset()
	var hero := _new_hero()
	var source := _new_source("forest", "forest/validation_chest")
	source.location_id = ""
	var empty_location_result := source.try_claim(hero)

	_expect_equal(
		empty_location_result,
		WorldLootSource.ClaimResult.INVALID_CONFIGURATION,
		"an empty location ID is rejected"
	)
	_expect_true(not source.interact_area.monitoring, "invalid sources disable interaction")

	source.location_id = "forest"
	source.loot_source_id = ""
	var empty_source_result := source.try_claim(hero)

	_expect_equal(
		empty_source_result,
		WorldLootSource.ClaimResult.INVALID_CONFIGURATION,
		"an empty loot-source ID is rejected"
	)
	_expect_equal(hero.inventory.gold, 0, "invalid sources cannot grant rewards")
	source.free()

func _test_duplicate_ids_in_one_location_are_detected() -> void:
	WorldManager.reset()
	var first_source := _new_source("forest", "forest/first_chest")
	var second_source := _new_source("forest", "forest/second_chest")
	second_source.loot_source_id = first_source.loot_source_id

	var errors := second_source.get_validation_errors()

	_expect_equal(errors.size(), 1, "duplicate loot IDs produce one validation error")
	_expect_contains(errors[0], "Duplicate world-loot ID", "duplicate validation explains the conflict")
	first_source.free()
	second_source.free()

func _test_same_id_in_different_locations_is_allowed() -> void:
	WorldManager.reset()
	var forest_source := _new_source("forest", "shared/test_chest")
	var cave_source := _new_source("cave", "shared/test_chest")

	_expect_equal(
		cave_source.get_validation_errors(),
		[],
		"loot ID uniqueness is scoped to one location"
	)
	forest_source.free()
	cave_source.free()

func _new_source(location: String, source_id: String) -> TestWorldLootSource:
	var source := TEST_LOOT_SOURCE.new() as TestWorldLootSource
	var interact_area := INTERACT_AREA_SCENE.instantiate() as InteractArea
	interact_area.name = "InteractArea"
	source.add_child(interact_area)
	source.location_id = location
	source.loot_source_id = source_id
	source.loot_table = _new_deterministic_table()
	add_child(source)
	return source

func _new_deterministic_table() -> DropTable:
	var entry := DropEntry.new()
	entry.item_id = "lesser_healing_potion"
	entry.chance = 1.0
	entry.min_count = 2
	entry.max_count = 2
	var table := DropTable.new()
	table.entries = [entry]
	table.min_gold = 10
	table.max_gold = 10
	return table

func _new_hero() -> Hero:
	var hero := HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	hero.inventory.gold = 0
	hero.inventory.potions.clear()
	hero.inventory.quest_items.clear()
	hero.inventory.weapon_stash.clear()
	return hero

func _reset_claim_signal() -> void:
	_last_claim_result = WorldLootSource.ClaimResult.IN_PROGRESS
	_last_claim_rewards.clear()
	_claim_signal_count = 0

func _on_claim_finished(
	result: WorldLootSource.ClaimResult,
	rewards: Array[RewardEntry]
) -> void:
	_last_claim_result = result
	_last_claim_rewards = rewards
	_claim_signal_count += 1
