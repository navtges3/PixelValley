extends TestCase

const TEST_SAVE_SLOT := 999997
const PARTY_SAVE_MIGRATOR := preload("res://scripts/save/party_save_migrator.gd")


func run_tests() -> int:
	_begin_test_run()
	_test_members_share_one_inventory()
	_test_equip_transfers_weapon_from_shared_inventory()
	_test_swap_returns_previous_weapon()
	_test_equipped_weapon_cannot_be_granted_twice()
	_test_roster_and_active_party_limits()
	_test_active_party_membership()
	_test_party_save_migration()
	_test_party_builds_battle_party_from_same_heroes()
	_test_invalid_equipment_operations_do_not_mutate_state()
	_test_save_data_round_trip_preserves_shared_and_equipped_items()
	_test_full_save_load_round_trip()
	_test_rest_all_restores_every_member()
	_test_reorder_active_members()
	_test_removal_constraints()
	_test_downed_hero_eligibility_and_battle_party()
	_test_battle_party_order_matches_active_order()
	_test_equip_returns_old_weapon_and_prevents_duplicate_assignment()
	_test_class_locked_equip_and_unlisted_weapon()
	_test_party_changed_signal()
	_test_rest_all_revives_downed_heroes()
	if SaveManager.has_save_data(TEST_SAVE_SLOT):
		SaveManager.delete_slot(TEST_SAVE_SLOT)
	return _finish_test_run("Party tests")


func _test_members_share_one_inventory() -> void:
	var party := Party.new()
	var knight := HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	var assassin := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)

	_expect_true(party.add_member(knight), "party accepts its first member")
	_expect_true(party.add_member(assassin), "party accepts its second member")


func _test_equip_transfers_weapon_from_shared_inventory() -> void:
	var party := _new_party()
	var hero := party.members[0]
	party.inventory.add_weapon("bronze_mace")

	_expect_true(party.equip_weapon(hero, "bronze_mace"), "stored weapon equips")
	_expect_false("bronze_mace" in party.inventory.weapon_stash, "equipped weapon leaves shared stash")
	_expect_equal(ItemLoader.get_item_id(hero.equipped_weapon), "bronze_mace", "Hero owns equipped weapon")


func _test_swap_returns_previous_weapon() -> void:
	var party := _new_party()
	var hero := party.members[0]
	var previous_id := ItemLoader.get_item_id(hero.equipped_weapon)
	party.inventory.add_weapon("bronze_mace")

	party.equip_weapon(hero, "bronze_mace")

	_expect_true(previous_id in party.inventory.weapon_stash, "swap returns prior weapon to shared stash")


func _test_equipped_weapon_cannot_be_granted_twice() -> void:
	var party := _new_party()
	var equipped_id := ItemLoader.get_item_id(party.members[0].equipped_weapon)
	var weapon := ItemLoader.get_item(equipped_id) as Weapon

	_expect_true(party.has_weapon(equipped_id), "Party recognizes an equipped weapon as owned")
	RewardService.grant_weapon(party, equipped_id)
	_expect_false(equipped_id in party.inventory.weapon_stash, "duplicate reward cannot add equipped weapon")
	_expect_equal(party.inventory.gold, weapon.value, "duplicate reward converts to gold")


func _test_roster_and_active_party_limits() -> void:
	var party := Party.new()
	for index: int in 5:
		var hero := HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
		_expect_true(party.add_member(hero), "Party accepts recruited roster member %d" % index)

	_expect_equal(party.members.size(), 5, "roster is not limited to active party size")
	_expect_equal(
		party.get_active_members().size(),
		Party.MAX_ACTIVE_MEMBERS,
		"active party is limited to four members"
	)


func _test_active_party_membership() -> void:
	var party := Party.new()
	var first := HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	var second := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	party.add_member(first)
	party.add_member(second)
	party.remove_from_active_party(second)

	_expect_true(party.add_to_active_party(second), "recruited member can rejoin active party")
	_expect_false(party.add_to_active_party(HeroLoader.new_hero(Hero.HeroClass.PRINCESS)),
		"unrecruited member cannot join active party")
	_expect_equal(party.get_active_members()[1], second, "active party preserves member identity")


func _test_party_save_migration() -> void:
	var legacy := PARTY_SAVE_MIGRATOR.migrate({
		"schema_version": 1,
		"data": {
			"members": [
				{"hero_name": "Knight"},
				{"hero_name": "Assassin"},
			],
		},
	}, false)
	var legacy_data: Dictionary = legacy["data"]
	_expect_equal(
		legacy["schema_version"],
		PARTY_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION,
		"legacy Party saves migrate to the current schema"
	)
	_expect_equal(
		legacy_data["active_member_ids"],
		["hero_0", "hero_1"],
		"legacy Party saves activate the first members"
	)
	_expect_equal(
		(legacy_data["members"][0] as Dictionary)["hero_id"],
		"hero_0",
		"legacy members receive stable IDs"
	)

	var invalid := PARTY_SAVE_MIGRATOR.migrate({
		"schema_version": PARTY_SAVE_MIGRATOR.CURRENT_SCHEMA_VERSION,
		"data": {
			"members": [
				{"hero_id": "knight"},
				{"hero_id": "assassin"},
			],
			"active_member_ids": ["missing", "knight", "knight", "assassin"],
		},
	}, false)
	_expect_equal(
		invalid["data"]["active_member_ids"],
		["knight", "assassin"],
		"invalid and duplicate active IDs are removed"
	)


func _test_party_builds_battle_party_from_same_heroes() -> void:
	var party := _new_party()
	var second_hero := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	party.add_member(second_hero)

	var battle_party := party.create_battle_party()
	var battle_members := battle_party.get_members()

	_expect_equal(battle_members.size(), 2, "BattleParty contains every persistent member")
	_expect_equal(battle_members[0], party.members[0], "BattleParty keeps the first Hero reference")
	_expect_equal(battle_members[1], party.members[1], "BattleParty keeps the second Hero reference")


func _test_invalid_equipment_operations_do_not_mutate_state() -> void:
	var party := _new_party()
	var outsider := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	var original_weapon := party.members[0].equipped_weapon

	_expect_false(
		party.equip_weapon(outsider, "bronze_mace"),
		"Party rejects equipping an outsider"
	)
	_expect_false(
		party.unequip_weapon(outsider),
		"Party rejects unequipping an outsider"
	)
	_expect_equal(
		party.members[0].equipped_weapon,
		original_weapon,
		"invalid equipment operations preserve the equipped weapon"
	)


func _test_save_data_round_trip_preserves_shared_and_equipped_items() -> void:
	var party := _new_party()
	var assassin := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	party.add_member(assassin)
	party.inventory.gold = 123
	party.inventory.add_potion("lesser_healing_potion", 2)
	party.inventory.add_weapon("bronze_mace")
	party.equip_weapon(party.members[0], "bronze_mace")

	var restored := SaveManager._load_party(SaveManager._get_party_data(party))

	_expect_equal(restored.members.size(), 2, "Party members survive serialization")
	_expect_equal(restored.active_member_ids, party.active_member_ids,
		"active formation survives serialization")
	_expect_equal(restored.inventory.gold, 123, "shared gold survives serialization")
	_expect_equal(
		restored.inventory.get_potion_count("lesser_healing_potion"),
		2,
		"shared consumables survive serialization"
	)
	_expect_equal(
		ItemLoader.get_item_id(restored.members[0].equipped_weapon),
		"bronze_mace",
		"equipped Hero weapon survives serialization"
	)


func _test_full_save_load_round_trip() -> void:
	GameState.reset_state()
	var party := Party.new()
	var knight := HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	var assassin := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	party.add_member(knight)
	party.add_member(assassin)
	party.inventory.gold = 321
	party.inventory.add_potion("lesser_healing_potion", 4)
	party.inventory.add_weapon("bronze_mace")
	party.equip_weapon(assassin, "bronze_mace")
	GameState.party = party
	GameState.hero = knight
	GameState.village = Village.new()
	GameState.village.name = "Party Test Village"
	GameState.village.inn = Inn.new()
	GameState.village.potion_shop = Shop.new()
	GameState.village.weapon_shop = Shop.new()
	GameState.quest_manager = QuestManager.new()
	GameState.quest_manager.new_game()
	SaveManager.save_slot = TEST_SAVE_SLOT
	SaveManager.save_game()

	GameState.reset_state()
	SaveManager.load_game(TEST_SAVE_SLOT)

	var restored := GameState.party
	_expect_not_null(restored, "full save/load restores the Party")
	_expect_equal(restored.members.size(), 2, "full save/load restores all Party members")
	_expect_equal(restored.active_member_ids, party.active_member_ids,
		"full save/load restores active formation")
	_expect_equal(restored.inventory.gold, 321, "full save/load restores shared gold")
	_expect_equal(
		restored.inventory.get_potion_count("lesser_healing_potion"),
		4,
		"full save/load restores shared consumables"
	)
	_expect_equal(
		ItemLoader.get_item_id(restored.members[1].equipped_weapon),
		"bronze_mace",
		"full save/load restores Hero equipment"
	)


func _test_rest_all_restores_every_member() -> void:
	var party := Party.new()
	var knight := HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	var assassin := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	party.add_member(knight)
	party.add_member(assassin)

	knight.current_hp = 5
	knight.current_nrg = 2
	assassin.current_hp = 1
	assassin.current_nrg = 0

	party.rest_all()

	for hero: Hero in party.members:
		_expect_equal(
			hero.current_hp,
			hero.max_hp,
			"%s HP is fully restored by rest_all" % hero.get_class_name()
		)
		_expect_equal(
			hero.current_nrg,
			hero.max_nrg,
			"%s NRG is fully restored by rest_all" % hero.get_class_name()
		)


func _new_party() -> Party:
	var party := Party.new()
	party.add_member(HeroLoader.new_hero(Hero.HeroClass.KNIGHT))
	return party
