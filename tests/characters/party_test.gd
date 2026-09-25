extends TestCase

const TEST_SAVE_SLOT := 999997
const PARTY_SAVE_MIGRATOR := preload("res://scripts/save/party_save_migrator.gd")

var _party_changed_count: int = 0


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
	_test_set_leader()
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
	_expect_equal(party.members.size(), 2, "both heroes are on the roster")
	_expect_true(party.is_leader(knight), "the first recruit is the leader")


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
	var princess := HeroLoader.new_hero(Hero.HeroClass.PRINCESS)
	party.add_member(knight)
	party.add_member(assassin)
	party.add_member(princess)
	party.inventory.gold = 321
	party.inventory.add_potion("lesser_healing_potion", 4)
	party.inventory.add_weapon("silent_dirk")
	party.inventory.add_weapon("focus_orb")
	party.equip_weapon(assassin, "silent_dirk")
	party.equip_weapon(princess, "focus_orb")
	# Formation: [knight, princess]; the assassin waits in reserve with a weapon.
	party.move_active_member(princess, -1)
	party.remove_from_active_party(assassin)
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
	_expect_equal(restored.members.size(), 3, "full save/load restores all Party members")
	_expect_equal(restored.active_member_ids, party.active_member_ids,
		"full save/load restores active formation")
	_expect_equal(
		_active_order(restored),
		[knight.hero_id, princess.hero_id],
		"full save/load restores a reordered formation with a reserve member"
	)
	_expect_equal(restored.inventory.gold, 321, "full save/load restores shared gold")
	_expect_equal(
		restored.inventory.get_potion_count("lesser_healing_potion"),
		4,
		"full save/load restores shared consumables"
	)
	_expect_equal(
		ItemLoader.get_item_id(restored.members[1].equipped_weapon),
		"silent_dirk",
		"full save/load restores equipment on a reserve Hero"
	)
	_expect_equal(
		ItemLoader.get_item_id(restored.members[2].equipped_weapon),
		"focus_orb",
		"full save/load restores equipment on an active Hero"
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


func _test_reorder_active_members() -> void:
	var party := _new_party()
	var leader := party.members[0]
	var second := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	var third := HeroLoader.new_hero(Hero.HeroClass.PRINCESS)
	party.add_member(second)
	party.add_member(third)
	_expect_equal(
		_active_order(party),
		[leader.hero_id, second.hero_id, third.hero_id],
		"recruits join the active party in recruitment order"
	)

	_expect_true(party.move_active_member(second, -1), "a member can move up")
	_expect_equal(
		_active_order(party),
		[second.hero_id, leader.hero_id, third.hero_id],
		"moving up swaps with the previous slot"
	)
	_expect_false(party.move_active_member(second, -1), "the first slot cannot move up")
	_expect_false(party.move_active_member(third, 1), "the last slot cannot move down")
	_expect_equal(
		_active_order(party),
		[second.hero_id, leader.hero_id, third.hero_id],
		"rejected moves leave the order unchanged"
	)

	_expect_true(party.move_active_member(leader, 1), "a member can move down")
	_expect_equal(
		_active_order(party),
		[second.hero_id, third.hero_id, leader.hero_id],
		"moving down swaps with the next slot"
	)
	_expect_equal(party.members[0], leader, "reordering does not change roster order")
	_expect_true(party.is_leader(leader), "the leader stays the leader after being moved")

	_expect_false(party.move_active_member(null, 1), "a null hero cannot move")
	_expect_false(
		party.move_active_member(HeroLoader.new_hero(Hero.HeroClass.KNIGHT), 1),
		"a hero outside the roster cannot move"
	)

	var full_party := _new_party()
	for hero_class: Hero.HeroClass in [
		Hero.HeroClass.ASSASSIN,
		Hero.HeroClass.PRINCESS,
		Hero.HeroClass.KNIGHT,
		Hero.HeroClass.ASSASSIN,
	]:
		full_party.add_member(HeroLoader.new_hero(hero_class))
	var reserve := full_party.members[4]
	_expect_false(full_party.active_member_ids.has(reserve.hero_id), "fifth hero starts in reserve")
	_expect_false(full_party.move_active_member(reserve, -1), "a reserve hero cannot be reordered")


func _test_removal_constraints() -> void:
	var party := _new_party()
	var leader := party.members[0]
	var second := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	party.add_member(second)

	_expect_false(party.remove_from_active_party(leader), "the leader cannot leave the active party")
	_expect_equal(party.active_member_ids.size(), 2, "a rejected leader removal keeps both members active")

	_expect_true(party.remove_from_active_party(second), "a non-leader can leave the active party")
	_expect_true(party.has_member(second), "leaving the active party keeps the hero on the roster")
	_expect_false(party.remove_from_active_party(second), "a reserve hero cannot be removed twice")
	_expect_false(party.remove_from_active_party(leader), "the last active member cannot be removed")
	_expect_equal(_active_order(party), [leader.hero_id], "the leader remains as the only active member")

	# Loaded or migrated data can leave a non-leader as the only active member.
	party.set_active_member_ids([second.hero_id])
	_expect_false(
		party.remove_from_active_party(second),
		"the last active member cannot be removed even when it is not the leader"
	)
	_expect_equal(_active_order(party), [second.hero_id], "the sole active member stays active")

	_expect_false(
		party.remove_from_active_party(HeroLoader.new_hero(Hero.HeroClass.PRINCESS)),
		"a hero outside the roster cannot be removed"
	)


func _test_downed_hero_eligibility_and_battle_party() -> void:
	var party := _new_party()
	var leader := party.members[0]
	var second := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	var third := HeroLoader.new_hero(Hero.HeroClass.PRINCESS)
	party.add_member(second)
	party.add_member(third)

	_expect_true(party.is_eligible(second), "a healthy roster member is eligible")
	_expect_false(
		party.is_eligible(HeroLoader.new_hero(Hero.HeroClass.KNIGHT)),
		"a hero outside the roster is not eligible"
	)

	second.current_hp = 0
	_expect_false(party.is_eligible(second), "a downed hero is not eligible")
	_expect_equal(
		_ids(party.get_eligible_active_members()),
		[leader.hero_id, third.hero_id],
		"eligible active members skip downed heroes"
	)
	_expect_equal(
		_battle_order(party.create_battle_party()),
		[leader.hero_id, third.hero_id],
		"the battle party skips downed heroes"
	)
	_expect_equal(party.get_active_members().size(), 3, "a downed hero stays in the active party")
	_expect_true(party.can_fight(), "the party can fight while any active hero is up")

	var solo := _new_party()
	solo.members[0].current_hp = 0
	_expect_false(solo.can_fight(), "a party with no eligible active hero cannot fight")
	_expect_true(
		solo.create_battle_party().get_members().is_empty(),
		"no eligible heroes produces an empty battle party"
	)

	var reserve_party := _new_party()
	var recruit := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	reserve_party.add_member(recruit)
	reserve_party.remove_from_active_party(recruit)
	recruit.current_hp = 0
	_expect_false(reserve_party.add_to_active_party(recruit), "a downed hero cannot join the active party")
	recruit.current_hp = recruit.max_hp
	_expect_true(reserve_party.add_to_active_party(recruit), "a healthy hero can join the active party")


func _test_battle_party_order_matches_active_order() -> void:
	var party := _new_party()
	var leader := party.members[0]
	var second := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	var third := HeroLoader.new_hero(Hero.HeroClass.PRINCESS)
	party.add_member(second)
	party.add_member(third)

	party.move_active_member(third, -1)
	party.move_active_member(third, -1)
	_expect_equal(
		_battle_order(party.create_battle_party()),
		[third.hero_id, leader.hero_id, second.hero_id],
		"the battle party follows the formation order"
	)

	var full_party := _new_party()
	for hero_class: Hero.HeroClass in [
		Hero.HeroClass.ASSASSIN,
		Hero.HeroClass.PRINCESS,
		Hero.HeroClass.KNIGHT,
		Hero.HeroClass.ASSASSIN,
	]:
		full_party.add_member(HeroLoader.new_hero(hero_class))
	var reserve := full_party.members[4]
	var battle_ids := _battle_order(full_party.create_battle_party())
	_expect_equal(battle_ids.size(), Party.MAX_ACTIVE_MEMBERS, "the battle party is capped at the active size")
	_expect_false(battle_ids.has(reserve.hero_id), "reserve heroes do not join the battle party")


func _test_equip_returns_old_weapon_and_prevents_duplicate_assignment() -> void:
	var party := _new_party()
	var knight := party.members[0]
	var assassin := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	var second_assassin := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	party.add_member(assassin)
	party.add_member(second_assassin)
	var knight_default := ItemLoader.get_item_id(knight.equipped_weapon)
	var assassin_default := ItemLoader.get_item_id(assassin.equipped_weapon)
	party.inventory.add_weapon("silent_dirk")

	_expect_true(party.equip_weapon(assassin, "silent_dirk"), "a stashed weapon equips on the second hero")
	_expect_equal(
		ItemLoader.get_item_id(assassin.equipped_weapon),
		"silent_dirk",
		"the second hero owns the new weapon"
	)
	_expect_true(assassin_default in party.inventory.weapon_stash, "the replaced weapon returns to the shared stash")
	_expect_false("silent_dirk" in party.inventory.weapon_stash, "the equipped weapon leaves the shared stash")
	_expect_equal(
		ItemLoader.get_item_id(knight.equipped_weapon),
		knight_default,
		"equipping on one hero does not change another hero's weapon"
	)
	_expect_true(party.has_weapon("silent_dirk"), "an equipped weapon still counts as owned")

	_expect_false(
		party.equip_weapon(second_assassin, "silent_dirk"),
		"a weapon equipped by one hero cannot be equipped by another"
	)
	_expect_equal(
		ItemLoader.get_item_id(assassin.equipped_weapon),
		"silent_dirk",
		"a rejected duplicate equip leaves the owner unchanged"
	)

	_expect_true(party.unequip_weapon(knight), "a hero can unequip their weapon")
	_expect_null(knight.equipped_weapon, "unequipping clears the hero's weapon")
	_expect_true(knight_default in party.inventory.weapon_stash, "the unequipped weapon returns to the shared stash")
	_expect_false(party.unequip_weapon(knight), "a hero without a weapon cannot unequip")
	_expect_true(party.equip_weapon(knight, knight_default), "an unequipped weapon can be equipped again")


func _test_class_locked_equip_and_unlisted_weapon() -> void:
	var party := _new_party()
	var knight := party.members[0]
	var assassin := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	party.add_member(assassin)
	var assassin_weapon := assassin.equipped_weapon
	party.inventory.add_weapon("iron_longsword")
	party.inventory.add_weapon("focus_orb")

	_expect_false(party.equip_weapon(assassin, "iron_longsword"), "an assassin cannot equip a knight weapon")
	_expect_false(party.equip_weapon(knight, "focus_orb"), "a knight cannot equip a princess weapon")
	_expect_true("iron_longsword" in party.inventory.weapon_stash, "a rejected equip keeps the weapon in the stash")
	_expect_true("focus_orb" in party.inventory.weapon_stash, "a rejected equip keeps the weapon in the stash")
	_expect_equal(assassin.equipped_weapon, assassin_weapon, "a rejected equip leaves the equipped weapon unchanged")
	_expect_true(party.equip_weapon(knight, "iron_longsword"), "a knight can equip a knight weapon")

	for hero_class: Hero.HeroClass in WeaponDatabase.CLASS_WEAPON_TABLE:
		var rarities: Dictionary = WeaponDatabase.CLASS_WEAPON_TABLE[hero_class]
		for rarity: Item.Rarity in rarities:
			for weapon_id: String in rarities[rarity]:
				_expect_not_null(ItemLoader.get_item(weapon_id), "%s is registered with ItemLoader" % weapon_id)
				for other_class: Hero.HeroClass in [
					Hero.HeroClass.KNIGHT,
					Hero.HeroClass.ASSASSIN,
					Hero.HeroClass.PRINCESS,
				]:
					_expect_equal(
						WeaponDatabase.can_class_equip(other_class, weapon_id),
						other_class == hero_class,
						"%s is equippable only by its own class" % weapon_id
					)

	for hero_class: Hero.HeroClass in [
		Hero.HeroClass.KNIGHT,
		Hero.HeroClass.ASSASSIN,
		Hero.HeroClass.PRINCESS,
	]:
		_expect_true(
			WeaponDatabase.can_class_equip(hero_class, "weapon_missing_from_class_table"),
			"a weapon listed for no class is equippable by any class"
		)


func _test_party_changed_signal() -> void:
	var party := _new_party()
	var leader := party.members[0]
	var second := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	party.party_changed.connect(_on_party_changed)
	party.inventory.add_weapon("silent_dirk")
	party.inventory.add_weapon("iron_longsword")

	_expect_equal(_changes_from(party.add_member.bind(second)), 1, "add_member emits party_changed")
	_expect_equal(_changes_from(party.add_member.bind(second)), 0, "a duplicate add_member emits nothing")

	_expect_equal(_changes_from(party.remove_from_active_party.bind(second)), 1, "removal emits party_changed")
	_expect_equal(_changes_from(party.remove_from_active_party.bind(second)), 0, "a repeated removal emits nothing")
	_expect_equal(_changes_from(party.remove_from_active_party.bind(leader)), 0, "a rejected leader removal emits nothing")

	_expect_equal(_changes_from(party.add_to_active_party.bind(second)), 1, "rejoining emits party_changed")
	_expect_equal(_changes_from(party.add_to_active_party.bind(second)), 0, "a repeated rejoin emits nothing")

	_expect_equal(_changes_from(party.move_active_member.bind(second, -1)), 1, "a move emits party_changed")
	_expect_equal(_changes_from(party.move_active_member.bind(second, -1)), 0, "a rejected move emits nothing")

	_expect_equal(_changes_from(party.equip_weapon.bind(second, "silent_dirk")), 1, "equipping emits party_changed")
	_expect_equal(
		_changes_from(party.equip_weapon.bind(second, "iron_longsword")),
		0,
		"a class-locked equip emits nothing"
	)
	_expect_equal(_changes_from(party.unequip_weapon.bind(second)), 1, "unequipping emits party_changed")
	_expect_equal(_changes_from(party.unequip_weapon.bind(second)), 0, "a repeated unequip emits nothing")

	_expect_equal(_changes_from(party.set_leader.bind(second)), 1, "set_leader emits party_changed")
	_expect_equal(_changes_from(party.set_leader.bind(second)), 0, "a repeated set_leader emits nothing")


func _test_set_leader() -> void:
	var party := _new_party()
	var leader := party.members[0]
	var second := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	var third := HeroLoader.new_hero(Hero.HeroClass.PRINCESS)
	party.add_member(second)
	party.add_member(third)
	var active_before := party.active_member_ids.duplicate()

	_expect_true(party.set_leader(second), "a non-leader member can become leader")
	_expect_equal(party.members[0], second, "the new leader moves to members[0]")
	_expect_true(party.is_leader(second), "is_leader returns true for the new leader")
	_expect_false(party.is_leader(leader), "is_leader returns false for the old leader")
	_expect_equal(party.members[1], leader, "the old leader shifts down one slot")
	_expect_equal(party.members[2], third, "later members keep their relative order")
	_expect_equal(
		party.active_member_ids,
		active_before,
		"set_leader does not change active formation order"
	)

	_expect_false(party.set_leader(second), "the current leader cannot be promoted again")
	_expect_equal(party.members[0], second, "a rejected set_leader leaves members unchanged")

	_expect_false(
		party.set_leader(HeroLoader.new_hero(Hero.HeroClass.KNIGHT)),
		"a hero outside the roster cannot become leader"
	)
	_expect_equal(party.members[0], second, "a rejected outsider leaves the leader unchanged")


func _test_rest_all_revives_downed_heroes() -> void:
	var party := _new_party()
	var assassin := HeroLoader.new_hero(Hero.HeroClass.ASSASSIN)
	party.add_member(assassin)
	assassin.current_hp = 0

	_expect_false(party.is_eligible(assassin), "a downed hero starts ineligible")
	party.rest_all()
	_expect_equal(assassin.current_hp, assassin.max_hp, "rest_all restores a downed hero to full HP")
	_expect_true(party.is_eligible(assassin), "a rested hero is eligible again")
	_expect_equal(
		_battle_order(party.create_battle_party()),
		[party.members[0].hero_id, assassin.hero_id],
		"a rested hero rejoins the battle party"
	)


func _active_order(party: Party) -> Array:
	var order: Array = []
	for hero: Hero in party.get_active_members():
		order.append(hero.hero_id)
	return order


func _ids(heroes: Array[Hero]) -> Array:
	var ids: Array = []
	for hero: Hero in heroes:
		ids.append(hero.hero_id)
	return ids


func _battle_order(battle_party: BattleParty) -> Array:
	var order: Array = []
	for combatant: Combatant in battle_party.get_members():
		order.append((combatant as Hero).hero_id)
	return order


func _changes_from(action: Callable) -> int:
	var before := _party_changed_count
	action.call()
	return _party_changed_count - before


func _on_party_changed() -> void:
	_party_changed_count += 1


func _new_party() -> Party:
	var party := Party.new()
	party.add_member(HeroLoader.new_hero(Hero.HeroClass.KNIGHT))
	return party
