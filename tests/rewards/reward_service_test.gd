extends TestCase


func run_tests() -> int:
	_begin_test_run()
	_test_grant_applies_authored_reward()
	_test_zero_values_are_ignored()
	_test_potion_quantity_is_granted()
	_test_quest_item_is_granted()
	_test_quest_item_inventory_round_trip()
	_test_new_weapon_is_added_to_stash()
	_test_duplicate_weapon_is_sold()
	_test_random_weapon_adds_an_available_weapon()
	_test_random_weapon_uses_fallback_when_pool_is_exhausted()
	_test_deterministic_drop_table_rolls_all_supported_loot()
	_test_drop_table_keeps_multiple_weapons()
	_test_drop_table_preserves_random_weapon_configuration()
	_test_grant_loot_applies_gold_and_item_quantities()
	_test_grant_loot_skips_only_unknown_items()
	_test_grant_loot_grants_multiple_weapons()
	_test_grant_loot_uses_random_weapon_fallback()
	_test_empty_loot_produces_no_entries()
	_test_battle_rewards_use_generalized_loot_pipeline()
	return _finish_test_run("Reward service tests")


func _test_grant_applies_authored_reward() -> void:
	var hero := _new_hero()
	var reward := Reward.new()
	reward.experience = 10
	reward.gold = 25
	reward.items = ["lesser_healing_potion"]

	var entries := RewardService.grant(reward, hero)

	_expect_equal(hero.experience, 10, "authored reward grants experience")
	_expect_equal(hero.inventory.gold, 25, "authored reward grants gold")
	_expect_equal(
		hero.inventory.potions.get("lesser_healing_potion", 0),
		1,
		"authored reward grants its potion"
	)
	_expect_equal(entries.size(), 3, "authored reward reports each applied grant")


func _test_zero_values_are_ignored() -> void:
	var hero := _new_hero()
	var reward := Reward.new()

	var entries := RewardService.grant(reward, hero)

	_expect_equal(hero.experience, 0, "zero experience leaves the hero unchanged")
	_expect_equal(hero.inventory.gold, 0, "zero gold leaves the inventory unchanged")
	_expect_equal(entries.size(), 0, "zero-value rewards produce no display entries")


func _test_potion_quantity_is_granted() -> void:
	var hero := _new_hero()
	var entry := RewardService.grant_potion(hero, "lesser_healing_potion", 3)

	_expect_not_null(entry, "valid potion grant returns a reward entry")
	_expect_equal(
		hero.inventory.potions.get("lesser_healing_potion", 0),
		3,
		"potion grant applies the requested quantity"
	)
	_expect_contains(entry.display_text, "3x", "potion entry reports the granted quantity")


func _test_quest_item_is_granted() -> void:
	var hero := _new_hero()
	var entry := RewardService.grant_item(hero, "inn_key")

	_expect_not_null(entry, "valid quest-item grant returns a reward entry")
	_expect_equal(
		hero.inventory.get_quest_item_count("inn_key"),
		1,
		"quest-item grant adds the item to inventory"
	)
	_expect_contains(entry.display_text, "Brass Inn Key", "quest-item reward names the item")


func _test_quest_item_inventory_round_trip() -> void:
	var inventory := Inventory.new()
	inventory.add_quest_item("inn_key")
	var saved_data := SaveManager._get_inventory_data(inventory)
	var restored := SaveManager._load_inventory(saved_data)

	_expect_equal(
		restored.get_quest_item_count("inn_key"),
		1,
		"quest items survive inventory save/load"
	)


func _test_new_weapon_is_added_to_stash() -> void:
	var hero := _new_hero()
	var entry := RewardService.grant_weapon(hero, "bronze_mace")

	_expect_not_null(entry, "valid weapon grant returns a reward entry")
	_expect_true(
		hero.inventory.has_weapon_in_stash("bronze_mace"),
		"new weapon is added to the recipient inventory"
	)
	_expect_equal(hero.inventory.gold, 0, "new weapon does not grant duplicate gold")


func _test_duplicate_weapon_is_sold() -> void:
	var hero := _new_hero()
	hero.inventory.weapon_stash.append("bronze_mace")
	var weapon := ItemLoader.get_item("bronze_mace") as Weapon

	var entry := RewardService.grant_weapon(hero, "bronze_mace")

	_expect_not_null(entry, "duplicate weapon grant returns a reward entry")
	_expect_equal(hero.inventory.gold, weapon.value, "duplicate weapon awards its sale value")
	_expect_equal(
		hero.inventory.weapon_stash.count("bronze_mace"),
		1,
		"duplicate weapon is not added to the stash twice"
	)
	_expect_contains(entry.display_text, "duplicate", "duplicate weapon entry explains the sale")


func _test_random_weapon_adds_an_available_weapon() -> void:
	var hero := _new_hero()
	var entry := RewardService.grant_random_weapon(hero, Item.Rarity.COMMON)

	_expect_not_null(entry, "available random weapon grant returns a reward entry")
	_expect_equal(hero.inventory.weapon_stash.size(), 1, "random weapon is added to the stash")
	_expect_true(
		hero.inventory.weapon_stash[0] in WeaponDatabase.CLASS_WEAPON_TABLE[hero.hero_class][Item.Rarity.COMMON],
		"random weapon matches the recipient class and requested rarity"
	)
	_expect_equal(hero.inventory.gold, 0, "available random weapon does not grant fallback gold")


func _test_random_weapon_uses_fallback_when_pool_is_exhausted() -> void:
	var hero := _new_hero()
	var common_weapons: Array = WeaponDatabase.CLASS_WEAPON_TABLE.get(
		hero.hero_class,
		{}
	).get(Item.Rarity.COMMON, [])
	for weapon_id: String in common_weapons:
		if not hero.inventory.has_weapon_in_stash(weapon_id):
			hero.inventory.weapon_stash.append(weapon_id)

	var entry := RewardService.grant_random_weapon(hero, Item.Rarity.COMMON)
	var expected_gold := WeaponDatabase.get_gold_fallback_for_rarity(Item.Rarity.COMMON)

	_expect_not_null(entry, "exhausted random weapon grant returns a fallback entry")
	_expect_equal(hero.inventory.gold, expected_gold, "exhausted weapon pool grants fallback gold")
	_expect_contains(entry.display_text, "No new weapon", "fallback entry explains the substitution")


func _test_deterministic_drop_table_rolls_all_supported_loot() -> void:
	var table := DropTable.new()
	table.entries = [
		_new_drop_entry("lesser_healing_potion", 3),
		_new_drop_entry("inn_key", 2),
		_new_drop_entry("bronze_mace", 4),
	]
	table.min_gold = 17
	table.max_gold = 17
	table.weapon_chance = 1.0

	var loot: Dictionary = table.roll()
	var items: Dictionary = loot.get("items", {})

	_expect_equal(items.get("lesser_healing_potion", 0), 3, "drop table rolls potion quantities")
	_expect_equal(items.get("inn_key", 0), 2, "drop table rolls quest-item quantities")
	_expect_equal(items.get("bronze_mace", 0), 1, "drop table limits an authored weapon to one")
	_expect_equal(loot.get("gold", 0), 17, "equal gold bounds produce deterministic gold")
	_expect_true(loot.get("random_weapon", false), "random weapon rolls independently of authored weapons")


func _test_drop_table_keeps_multiple_weapons() -> void:
	var table := DropTable.new()
	table.entries = [
		_new_drop_entry("bronze_mace"),
		_new_drop_entry("iron_longsword"),
	]

	var items: Dictionary = table.roll().get("items", {})

	_expect_equal(items.size(), 2, "a drop result keeps every successful weapon entry")
	_expect_equal(items.get("bronze_mace", 0), 1, "the first authored weapon is retained")
	_expect_equal(items.get("iron_longsword", 0), 1, "additional authored weapons are retained")


func _test_drop_table_preserves_random_weapon_configuration() -> void:
	var table := DropTable.new()
	table.weapon_chance = 1.0
	table.weapon_rarity = Item.Rarity.RARE

	var loot: Dictionary = table.roll()

	_expect_true(loot.get("random_weapon", false), "100-percent random weapon chance always rolls")
	_expect_equal(loot.get("weapon_rarity"), Item.Rarity.RARE, "random weapon rarity is preserved")


func _test_grant_loot_applies_gold_and_item_quantities() -> void:
	var hero := _new_hero()
	var loot := {
		"items": {
			"lesser_healing_potion": 3,
			"inn_key": 2,
			"bronze_mace": 1,
		},
		"gold": 25,
		"random_weapon": false,
		"weapon_rarity": Item.Rarity.COMMON,
	}

	var entries := RewardService.grant_loot(loot, hero)

	_expect_equal(hero.inventory.gold, 25, "loot pipeline grants authored gold")
	_expect_equal(hero.inventory.get_potion_count("lesser_healing_potion"), 3, "loot pipeline grants potion quantities")
	_expect_equal(hero.inventory.get_quest_item_count("inn_key"), 2, "loot pipeline grants quest-item quantities")
	_expect_true(hero.inventory.has_weapon_in_stash("bronze_mace"), "loot pipeline grants an authored weapon")
	_expect_equal(entries.size(), 4, "loot pipeline reports every applied reward")


func _test_grant_loot_skips_only_unknown_items() -> void:
	var hero := _new_hero()
	var loot := {
		"items": {
			"missing_item": 1,
			"lesser_healing_potion": 2,
		},
	}

	var entries := RewardService.grant_loot(loot, hero)

	_expect_equal(hero.inventory.get_potion_count("lesser_healing_potion"), 2, "valid loot is granted after an invalid ID")
	_expect_equal(entries.size(), 1, "invalid loot does not create a presentation entry")


func _test_grant_loot_grants_multiple_weapons() -> void:
	var hero := _new_hero()
	var loot := {
		"items": {
			"bronze_mace": 3,
			"iron_longsword": 1,
		},
	}

	var entries := RewardService.grant_loot(loot, hero)

	_expect_equal(hero.inventory.weapon_stash.size(), 2, "loot service grants every distinct weapon")
	_expect_equal(entries.size(), 2, "every granted weapon is presented")


func _test_grant_loot_uses_random_weapon_fallback() -> void:
	var hero := _new_hero()
	var common_weapons: Array = WeaponDatabase.CLASS_WEAPON_TABLE.get(
		hero.hero_class,
		{}
	).get(Item.Rarity.COMMON, [])
	for weapon_id: String in common_weapons:
		hero.inventory.weapon_stash.append(weapon_id)
	var loot := {
		"items": {},
		"random_weapon": true,
		"weapon_rarity": Item.Rarity.COMMON,
	}

	var entries := RewardService.grant_loot(loot, hero)
	var expected_gold := WeaponDatabase.get_gold_fallback_for_rarity(Item.Rarity.COMMON)

	_expect_equal(hero.inventory.gold, expected_gold, "loot pipeline preserves random-weapon fallback gold")
	_expect_equal(entries.size(), 1, "random-weapon fallback is presented")


func _test_empty_loot_produces_no_entries() -> void:
	var hero := _new_hero()

	var entries := RewardService.grant_loot({}, hero)

	_expect_equal(entries.size(), 0, "empty loot produces no presentation entries")
	_expect_equal(hero.inventory.gold, 0, "empty loot leaves inventory unchanged")


func _test_battle_rewards_use_generalized_loot_pipeline() -> void:
	var hero := _new_hero()
	var monster := MonsterLoader.new_monster(MonsterLoader.MonsterID.GOBLIN)
	var table := DropTable.new()
	table.entries = [
		_new_drop_entry("lesser_healing_potion", 3),
		_new_drop_entry("inn_key", 2),
		_new_drop_entry("bronze_mace"),
	]
	table.min_gold = 7
	table.max_gold = 7
	monster.gold = 11
	monster.gold_variance = 0.0
	monster.loot = table
	var manager := BattleManager.new()
	manager.hero = hero
	manager.monster = monster

	var entries := manager._grant_victory_rewards()

	_expect_equal(hero.inventory.gold, 18, "battle grants monster gold and drop-table gold")
	_expect_equal(hero.inventory.get_potion_count("lesser_healing_potion"), 3, "battle preserves potion loot")
	_expect_equal(hero.inventory.get_quest_item_count("inn_key"), 2, "battle grants generalized item loot")
	_expect_true(hero.inventory.has_weapon_in_stash("bronze_mace"), "battle preserves authored weapon loot")
	_expect_equal(entries.size(), 6, "battle reports experience, gold, and every loot item")
	manager.free()


func _new_drop_entry(item_id: String, count: int = 1) -> DropEntry:
	var entry := DropEntry.new()
	entry.item_id = item_id
	entry.chance = 1.0
	entry.min_count = count
	entry.max_count = count
	return entry


func _new_hero() -> Hero:
	var hero := HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	hero.level = 1
	hero.experience = 0
	hero.inventory.gold = 0
	hero.inventory.potions.clear()
	hero.inventory.quest_items.clear()
	hero.inventory.weapon_stash.clear()
	return hero
