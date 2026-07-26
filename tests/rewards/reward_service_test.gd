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


func _new_hero() -> Hero:
	var hero := HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	hero.level = 1
	hero.experience = 0
	hero.inventory.gold = 0
	hero.inventory.potions.clear()
	hero.inventory.quest_items.clear()
	hero.inventory.weapon_stash.clear()
	return hero
