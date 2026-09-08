extends TestCase


func run_tests() -> int:
	_begin_test_run()
	_test_empty_party()
	_test_membership_and_order()
	_test_capacity_limit()
	_test_rejects_null_and_duplicates()
	_test_remove_member()
	_test_alive_member_queries()
	_test_accepts_heroes_and_monsters()
	return _finish_test_run("Battle party tests")


func _test_empty_party() -> void:
	var party := BattleParty.new()
	_expect_equal(party.get_members().size(), 0, "new party starts empty")
	_expect_equal(party.get_alive_members().size(), 0, "empty party has no alive members")
	_expect_false(party.has_living_members(), "empty party has no living members")


func _test_membership_and_order() -> void:
	var party := BattleParty.new()
	var first := _new_combatant(10)
	var second := _new_combatant(20)

	_expect_true(party.add_member(first), "first member can be added")
	_expect_true(party.add_member(second), "second member can be added")
	_expect_true(party.has_member(first), "party contains first member")
	_expect_true(party.has_member(second), "party contains second member")

	var members := party.get_members()
	_expect_equal(members.size(), 2, "party reports both members")
	_expect_equal(members[0], first, "party preserves first member order")
	_expect_equal(members[1], second, "party preserves second member order")


func _test_capacity_limit() -> void:
	var party := BattleParty.new()
	for index: int in BattleParty.MAX_MEMBERS:
		_expect_true(
			party.add_member(_new_combatant(index + 1)),
			"party accepts member %d within capacity" % (index + 1)
		)

	var extra := _new_combatant(100)
	_expect_false(party.add_member(extra), "party rejects member beyond capacity")
	_expect_equal(
		party.get_members().size(),
		BattleParty.MAX_MEMBERS,
		"party remains at maximum capacity"
	)


func _test_rejects_null_and_duplicates() -> void:
	var party := BattleParty.new()
	var member := _new_combatant(10)

	_expect_false(party.add_member(null), "party rejects null members")
	_expect_true(party.add_member(member), "party accepts an initial member")
	_expect_false(party.add_member(member), "party rejects duplicate members")
	_expect_equal(party.get_members().size(), 1, "duplicate is not added")


func _test_remove_member() -> void:
	var party := BattleParty.new()
	var first := _new_combatant(10)
	var second := _new_combatant(20)
	var third := _new_combatant(30)
	party.add_member(first)
	party.add_member(second)
	party.add_member(third)

	_expect_true(party.remove_member(second), "party removes an existing member")
	_expect_false(party.has_member(second), "removed member is no longer present")
	_expect_false(party.remove_member(second), "party rejects removing a missing member")

	var members := party.get_members()
	_expect_equal(members.size(), 2, "party contains remaining members")
	_expect_equal(members[0], first, "removal preserves first member order")
	_expect_equal(members[1], third, "removal preserves later member order")


func _test_alive_member_queries() -> void:
	var party := BattleParty.new()
	var living := _new_combatant(10)
	var defeated := _new_combatant(0)
	party.add_member(living)
	party.add_member(defeated)

	var alive_members := party.get_alive_members()
	_expect_equal(alive_members.size(), 1, "alive query excludes defeated members")
	_expect_equal(alive_members[0], living, "alive query returns living member")
	_expect_true(party.has_living_members(), "party with one living member is active")

	living.current_hp = 0
	_expect_equal(party.get_alive_members().size(), 0, "all-defeated party has no alive members")
	_expect_false(party.has_living_members(), "all-defeated party has no living members")


func _test_accepts_heroes_and_monsters() -> void:
	var party := BattleParty.new()
	var hero := Hero.new()
	var monster := Monster.new()

	_expect_true(party.add_member(hero), "party accepts heroes")
	_expect_true(party.add_member(monster), "party accepts monsters")
	_expect_equal(party.get_members().size(), 2, "party stores both combatant subtypes")


func _new_combatant(health: int) -> Combatant:
	var combatant := Combatant.new()
	combatant.max_hp = max(health, 1)
	combatant.current_hp = health
	return combatant
