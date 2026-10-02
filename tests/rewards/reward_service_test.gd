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
	_test_battle_rewards_split_experience_across_party()
	_test_battle_rewards_aggregate_multiple_monsters()
	_test_battle_rewards_merge_duplicate_potions()
	_test_battle_rewards_sell_duplicate_weapons_without_entry()
	_test_battle_rewards_skip_zero_experience_and_gold_entries()
	_test_battle_rewards_fold_random_weapon_fallback_into_gold()
	_test_battle_rewards_entry_order()
	return _finish_test_run("Reward service tests")


func _test_grant_applies_authored_reward() -> void:
	var hero := _new_hero()
	var reward := Reward.new()
	reward.experience = 10
	reward.gold = 25
	reward.items = ["lesser_healing_potion"]

	var entries := RewardService.grant(reward, GameState.party)

	_expect_equal(hero.experience, 10, "authored reward grants experience")
	_expect_equal(GameState.party.inventory.gold, 25, "authored reward grants gold")
	_expect_equal(
		GameState.party.inventory.potions.get("lesser_healing_potion", 0),
		1,
		"authored reward grants its potion"
	)
	_expect_equal(entries.size(), 3, "authored reward reports each applied grant")


func _test_zero_values_are_ignored() -> void:
	var hero := _new_hero()
	var reward := Reward.new()

	var entries := RewardService.grant(reward, GameState.party)

	_expect_equal(hero.experience, 0, "zero experience leaves the hero unchanged")
	_expect_equal(GameState.party.inventory.gold, 0, "zero gold leaves the inventory unchanged")
	_expect_equal(entries.size(), 0, "zero-value rewards produce no display entries")


func _test_potion_quantity_is_granted() -> void:
	var hero := _new_hero()
	var entry := RewardService.grant_potion(GameState.party, "lesser_healing_potion", 3)

	_expect_not_null(entry, "valid potion grant returns a reward entry")
	_expect_equal(
		GameState.party.inventory.potions.get("lesser_healing_potion", 0),
		3,
		"potion grant applies the requested quantity"
	)
	_expect_contains(entry.display_text, "3x", "potion entry reports the granted quantity")


func _test_quest_item_is_granted() -> void:
	var hero := _new_hero()
	var entry := RewardService.grant_item(GameState.party, "inn_key")

	_expect_not_null(entry, "valid quest-item grant returns a reward entry")
	_expect_equal(
		GameState.party.inventory.get_quest_item_count("inn_key"),
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
	var entry := RewardService.grant_weapon(GameState.party, "bronze_mace")

	_expect_not_null(entry, "valid weapon grant returns a reward entry")
	_expect_true(
		GameState.party.inventory.has_weapon_in_stash("bronze_mace"),
		"new weapon is added to the recipient inventory"
	)
	_expect_equal(GameState.party.inventory.gold, 0, "new weapon does not grant duplicate gold")


func _test_duplicate_weapon_is_sold() -> void:
	var hero := _new_hero()
	GameState.party.inventory.weapon_stash.append("bronze_mace")
	var weapon := ItemLoader.get_item("bronze_mace") as Weapon

	var entry := RewardService.grant_weapon(GameState.party, "bronze_mace")

	_expect_not_null(entry, "duplicate weapon grant returns a reward entry")
	_expect_equal(GameState.party.inventory.gold, weapon.value, "duplicate weapon awards its sale value")
	_expect_equal(
		GameState.party.inventory.weapon_stash.count("bronze_mace"),
		1,
		"duplicate weapon is not added to the stash twice"
	)
	_expect_contains(entry.display_text, "duplicate", "duplicate weapon entry explains the sale")


func _test_random_weapon_adds_an_available_weapon() -> void:
	var hero := _new_hero()
	var entry := RewardService.grant_random_party_weapon(GameState.party, Item.Rarity.COMMON)

	_expect_not_null(entry, "available random weapon grant returns a reward entry")
	_expect_equal(GameState.party.inventory.weapon_stash.size(), 1, "random weapon is added to the stash")
	_expect_true(
		GameState.party.inventory.weapon_stash[0] in WeaponDatabase.CLASS_WEAPON_TABLE[hero.hero_class][Item.Rarity.COMMON],
		"random weapon matches the recipient class and requested rarity"
	)
	_expect_equal(GameState.party.inventory.gold, 0, "available random weapon does not grant fallback gold")


func _test_random_weapon_uses_fallback_when_pool_is_exhausted() -> void:
	var hero := _new_hero()
	var common_weapons: Array = WeaponDatabase.CLASS_WEAPON_TABLE.get(
		hero.hero_class,
		{}
	).get(Item.Rarity.COMMON, [])
	for weapon_id: String in common_weapons:
		if not GameState.party.inventory.has_weapon_in_stash(weapon_id):
			GameState.party.inventory.weapon_stash.append(weapon_id)

	var entry := RewardService.grant_random_party_weapon(GameState.party, Item.Rarity.COMMON)
	var expected_gold := WeaponDatabase.get_gold_fallback_for_rarity(Item.Rarity.COMMON)

	_expect_not_null(entry, "exhausted random weapon grant returns a fallback entry")
	_expect_equal(GameState.party.inventory.gold, expected_gold, "exhausted weapon pool grants fallback gold")
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

	var entries := RewardService.grant_loot(loot, GameState.party)

	_expect_equal(GameState.party.inventory.gold, 25, "loot pipeline grants authored gold")
	_expect_equal(GameState.party.inventory.get_potion_count("lesser_healing_potion"), 3, "loot pipeline grants potion quantities")
	_expect_equal(GameState.party.inventory.get_quest_item_count("inn_key"), 2, "loot pipeline grants quest-item quantities")
	_expect_true(GameState.party.inventory.has_weapon_in_stash("bronze_mace"), "loot pipeline grants an authored weapon")
	_expect_equal(entries.size(), 4, "loot pipeline reports every applied reward")


func _test_grant_loot_skips_only_unknown_items() -> void:
	var hero := _new_hero()
	var loot := {
		"items": {
			"missing_item": 1,
			"lesser_healing_potion": 2,
		},
	}

	var entries := RewardService.grant_loot(loot, GameState.party)

	_expect_equal(GameState.party.inventory.get_potion_count("lesser_healing_potion"), 2, "valid loot is granted after an invalid ID")
	_expect_equal(entries.size(), 1, "invalid loot does not create a presentation entry")


func _test_grant_loot_grants_multiple_weapons() -> void:
	var hero := _new_hero()
	var loot := {
		"items": {
			"bronze_mace": 3,
			"iron_longsword": 1,
		},
	}

	var entries := RewardService.grant_loot(loot, GameState.party)

	_expect_equal(GameState.party.inventory.weapon_stash.size(), 2, "loot service grants every distinct weapon")
	_expect_equal(entries.size(), 2, "every granted weapon is presented")


func _test_grant_loot_uses_random_weapon_fallback() -> void:
	var hero := _new_hero()
	var common_weapons: Array = WeaponDatabase.CLASS_WEAPON_TABLE.get(
		hero.hero_class,
		{}
	).get(Item.Rarity.COMMON, [])
	for weapon_id: String in common_weapons:
		GameState.party.inventory.weapon_stash.append(weapon_id)
	var loot := {
		"items": {},
		"random_weapon": true,
		"weapon_rarity": Item.Rarity.COMMON,
	}

	var entries := RewardService.grant_loot(loot, GameState.party)
	var expected_gold := WeaponDatabase.get_gold_fallback_for_rarity(Item.Rarity.COMMON)

	_expect_equal(GameState.party.inventory.gold, expected_gold, "loot pipeline preserves random-weapon fallback gold")
	_expect_equal(entries.size(), 1, "random-weapon fallback is presented")


func _test_empty_loot_produces_no_entries() -> void:
	var hero := _new_hero()

	var entries := RewardService.grant_loot({}, GameState.party)

	_expect_equal(entries.size(), 0, "empty loot produces no presentation entries")
	_expect_equal(GameState.party.inventory.gold, 0, "empty loot leaves inventory unchanged")


func _test_battle_rewards_use_generalized_loot_pipeline() -> void:
	var hero := _new_hero()
	var monster := MonsterLoader.new_monster(MonsterLoader.MonsterID.GOBLIN_SCOUT)
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
	manager.persistent_party = GameState.party
	manager.player_party.add_member(hero)

	var entries := manager._grant_victory_rewards()

	_expect_equal(GameState.party.inventory.gold, 18, "battle grants monster gold and drop-table gold")
	_expect_equal(GameState.party.inventory.get_potion_count("lesser_healing_potion"), 3, "battle preserves potion loot")
	_expect_equal(GameState.party.inventory.get_quest_item_count("inn_key"), 2, "battle grants generalized item loot")
	_expect_true(GameState.party.inventory.has_weapon_in_stash("bronze_mace"), "battle preserves authored weapon loot")
	_expect_equal(entries.size(), 5, "battle reports one XP, gold, and each distinct loot item")
	manager.free()


func _test_battle_rewards_split_experience_across_party() -> void:
	var party := _new_party_with_heroes()
	var monster := MonsterLoader.new_monster(MonsterLoader.MonsterID.GOBLIN_SCOUT)
	monster.max_hp = 30
	var expected_xp: int = monster.calculate_experience()
	var manager := BattleManager.new()
	manager.persistent_party = party
	manager.player_party = party.create_battle_party()
	manager.monster = monster

	var entries := manager._grant_victory_rewards()

	for member: Hero in party.members:
		_expect_equal(
			member.experience,
			expected_xp,
			"%s receives full monster XP" % member.get_class_name()
		)
		_expect_equal(
			member.level,
			1,
			"%s level is unchanged when XP is below level-up threshold" % member.get_class_name()
		)

	var xp_entries: Array[RewardEntry] = []
	for entry: RewardEntry in entries:
		if entry.color == RewardEntry.COLOR_XP:
			xp_entries.append(entry)

	_expect_equal(
		xp_entries.size(),
		1,
		"victory rewards include one total XP entry"
	)
	for entry: RewardEntry in xp_entries:
		_expect_contains(
			entry.display_text,
			"%d Experience" % expected_xp,
			"XP entry reflects full monster XP amount"
		)
	manager.free()


func _test_battle_rewards_aggregate_multiple_monsters() -> void:
	var first_hero := _new_hero()
	var party: Party = GameState.party
	var second_hero := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	second_hero.level = 1
	second_hero.experience = 0
	party.add_member(second_hero)
	var first_monster := Monster.new()
	first_monster.max_hp = 10
	first_monster.gold = 10
	first_monster.gold_variance = 0.0
	var first_table := DropTable.new()
	first_table.min_gold = 3
	first_table.max_gold = 3
	first_monster.loot = first_table
	var second_monster := Monster.new()
	second_monster.max_hp = 20
	second_monster.gold = 15
	second_monster.gold_variance = 0.0
	var second_table := DropTable.new()
	second_table.min_gold = 4
	second_table.max_gold = 4
	second_monster.loot = second_table
	var manager := BattleManager.new()
	manager.persistent_party = party
	manager.player_party.add_member(first_hero)
	manager.player_party.add_member(second_hero)
	manager.enemy_party.add_member(first_monster)
	manager.enemy_party.add_member(second_monster)

	var total_xp: int = first_monster.calculate_experience() + second_monster.calculate_experience()
	var total_gold: int = (
		first_monster.gold + 3
		+ second_monster.gold + 4
	)
	var entries := manager._grant_victory_rewards()
	var xp_entries: Array[RewardEntry] = []
	var gold_entries: Array[RewardEntry] = []
	for entry: RewardEntry in entries:
		if entry.color == RewardEntry.COLOR_XP:
			xp_entries.append(entry)
		elif entry.color == RewardEntry.COLOR_GOLD:
			gold_entries.append(entry)

	_expect_equal(xp_entries.size(), 1, "multiple monsters produce one XP entry")
	_expect_equal(xp_entries[0].display_text, RewardEntry.experience(total_xp).display_text, "XP entry uses summed monster XP")
	_expect_equal(gold_entries.size(), 1, "multiple monsters produce one gold entry")
	_expect_equal(gold_entries[0].display_text, RewardEntry.gold(total_gold).display_text, "gold entry uses monster and loot gold totals")
	_expect_equal(party.inventory.gold, total_gold, "summed monster and loot gold reaches party inventory")
	_expect_equal(first_hero.experience, total_xp, "first hero receives the total XP")
	_expect_equal(second_hero.experience, total_xp, "second hero receives the total XP")
	manager.free()


func _test_battle_rewards_merge_duplicate_potions() -> void:
	var hero := _new_hero()
	var party: Party = GameState.party
	var first_monster := Monster.new()
	var first_table := DropTable.new()
	first_table.entries = [_new_drop_entry("lesser_healing_potion", 2)]
	first_monster.loot = first_table
	var second_monster := Monster.new()
	var second_table := DropTable.new()
	second_table.entries = [_new_drop_entry("lesser_healing_potion", 3)]
	second_monster.loot = second_table
	var manager := BattleManager.new()
	manager.persistent_party = party
	manager.player_party.add_member(hero)
	manager.enemy_party.add_member(first_monster)
	manager.enemy_party.add_member(second_monster)

	var entries := manager._grant_victory_rewards()
	var potion_entries: Array[RewardEntry] = []
	for entry: RewardEntry in entries:
		if entry.color == RewardEntry.COLOR_POTION:
			potion_entries.append(entry)

	_expect_equal(potion_entries.size(), 1, "matching potion drops produce one entry")
	_expect_contains(potion_entries[0].display_text, "5x", "potion entry combines both monster drops")
	_expect_equal(party.inventory.get_potion_count("lesser_healing_potion"), 5, "combined potion quantity reaches inventory")
	manager.free()


func _test_battle_rewards_sell_duplicate_weapons_without_entry() -> void:
	var hero := _new_hero()
	var party: Party = GameState.party
	var first_monster := Monster.new()
	var first_table := DropTable.new()
	first_table.entries = [_new_drop_entry("bronze_mace")]
	first_monster.loot = first_table
	var second_monster := Monster.new()
	var second_table := DropTable.new()
	second_table.entries = [_new_drop_entry("bronze_mace")]
	second_monster.loot = second_table
	var manager := BattleManager.new()
	manager.persistent_party = party
	manager.player_party.add_member(hero)
	manager.enemy_party.add_member(first_monster)
	manager.enemy_party.add_member(second_monster)
	var weapon := ItemLoader.get_item("bronze_mace") as Weapon

	var entries := manager._grant_victory_rewards()
	var weapon_entries: Array[RewardEntry] = []
	for entry: RewardEntry in entries:
		if entry.color == RewardEntry.COLOR_WEAPON:
			weapon_entries.append(entry)

	_expect_equal(party.inventory.weapon_stash.count("bronze_mace"), 1, "duplicate weapon drops add to stash once")
	_expect_equal(weapon_entries.size(), 1, "duplicate weapon drops produce one weapon entry")
	_expect_equal(party.inventory.gold, weapon.value, "duplicate weapon sale value is included in gold")
	manager.free()


func _test_battle_rewards_skip_zero_experience_and_gold_entries() -> void:
	var hero := _new_hero()
	var party: Party = GameState.party
	var monster := Monster.new()
	monster.max_hp = 0
	monster.gold = 0
	var manager := BattleManager.new()
	manager.persistent_party = party
	manager.player_party.add_member(hero)
	manager.enemy_party.add_member(monster)

	var entries := manager._grant_victory_rewards()

	_expect_equal(entries.size(), 0, "zero XP and gold produce no empty reward entries")
	_expect_equal(hero.experience, 0, "zero XP leaves the hero unchanged")
	_expect_equal(party.inventory.gold, 0, "zero gold leaves inventory unchanged")
	manager.free()


func _test_battle_rewards_fold_random_weapon_fallback_into_gold() -> void:
	var hero := _new_hero()
	var party: Party = GameState.party
	var rarity := Item.Rarity.COMMON
	var common_weapons: Array = WeaponDatabase.CLASS_WEAPON_TABLE.get(
		hero.hero_class,
		{}
	).get(rarity, [])
	for weapon_id: String in common_weapons:
		party.inventory.weapon_stash.append(weapon_id)

	var monster := MonsterLoader.new_monster(MonsterLoader.MonsterID.GOBLIN_SCOUT)
	monster.max_hp = 20
	monster.gold = 13
	monster.gold_variance = 0.0
	var table := DropTable.new()
	table.weapon_chance = 1.0
	table.weapon_rarity = rarity
	monster.loot = table
	var manager := BattleManager.new()
	manager.persistent_party = party
	manager.player_party.add_member(hero)
	manager.monster = monster

	var entries := manager._grant_victory_rewards()
	var gold_entries: Array[RewardEntry] = []
	for entry: RewardEntry in entries:
		if entry.color == RewardEntry.COLOR_GOLD:
			gold_entries.append(entry)
		_expect_true(
			entry.color != RewardEntry.COLOR_WEAPON
			and entry.color != RewardEntry.COLOR_WEAPON_SOLD,
			"exhausted random weapon pool produces no weapon entry"
		)

	var expected_gold := monster.gold + WeaponDatabase.get_gold_fallback_for_rarity(rarity)
	_expect_equal(gold_entries.size(), 1, "random weapon fallback is combined into one gold entry")
	_expect_equal(gold_entries[0].display_text, RewardEntry.gold(expected_gold).display_text, "gold entry includes random weapon fallback value")
	_expect_equal(party.inventory.gold, expected_gold, "party inventory receives monster and fallback gold")
	manager.free()


func _test_battle_rewards_entry_order() -> void:
	var hero := _new_hero()
	var monster := MonsterLoader.new_monster(MonsterLoader.MonsterID.GOBLIN_SCOUT)
	monster.max_hp = 20
	monster.gold = 12
	monster.gold_variance = 0.0
	var table := DropTable.new()
	table.entries = [
		_new_drop_entry("lesser_healing_potion"),
		_new_drop_entry("bronze_mace"),
	]
	monster.loot = table
	var manager := BattleManager.new()
	manager.persistent_party = GameState.party
	manager.player_party.add_member(hero)
	manager.monster = monster

	var entries := manager._grant_victory_rewards()
	var actual_colors: Array[Color] = []
	for entry: RewardEntry in entries:
		actual_colors.append(entry.color)
	var expected_colors: Array[Color] = [
		RewardEntry.COLOR_XP,
		RewardEntry.COLOR_GOLD,
		RewardEntry.COLOR_POTION,
		RewardEntry.COLOR_WEAPON,
	]

	_expect_equal(actual_colors, expected_colors, "battle reward entries are ordered XP, gold, potion, weapon")
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
	var party := Party.new()
	party.add_member(hero)
	GameState.party = party
	return hero


func _new_party_with_heroes() -> Party:
	var party := Party.new()
	var knight := HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	knight.level = 1
	knight.experience = 0
	var assassin := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	assassin.level = 1
	assassin.experience = 0
	var princess := HeroLoader.new_hero(Hero.HeroClass.PRINCESS)
	princess.level = 1
	princess.experience = 0
	party.add_member(knight)
	party.add_member(assassin)
	party.add_member(princess)
	GameState.party = party
	return party
