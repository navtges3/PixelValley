extends TestCase

const HERO_RESOURCES := [
	"res://resources/characters/heroes/assassin/assassin.tres",
	"res://resources/characters/heroes/knight/knight.tres",
	"res://resources/characters/heroes/princess/princess.tres",
]

const MONSTER_RESOURCES := [
	"res://resources/characters/monsters/goblin_scout.tres",
	"res://resources/characters/monsters/goblin_brute.tres",
	"res://resources/characters/monsters/orc_grunt.tres",
	"res://resources/characters/monsters/orc_chieftain/orc_chieftain.tres",
	"res://resources/characters/monsters/ogre_brute.tres",
	"res://resources/characters/monsters/ogre_warlord/ogre_warlord.tres",
	"res://resources/characters/monsters/ogre_king/ogre_king.tres",
]


func run_tests() -> int:
	_begin_test_run()
	_test_default_initiative()
	_test_resource_initiative_values()
	_test_damage_formula_uses_percentage_mitigation()
	return _finish_test_run("Combatant stat tests")


func _test_default_initiative() -> void:
	var combatant := Combatant.new()
	_expect_equal(combatant.initiative, 0, "combatants default to zero initiative")


func _test_resource_initiative_values() -> void:
	for resource_path: String in HERO_RESOURCES + MONSTER_RESOURCES:
		var combatant := load(resource_path) as Combatant
		_expect_not_null(combatant, "%s loads as a combatant" % resource_path)
		if combatant != null:
			_expect_true(
				combatant.initiative > 0,
				"%s defines a positive initiative" % resource_path
			)


func _test_damage_formula_uses_percentage_mitigation() -> void:
	var target := Combatant.new()
	target.defense = 100
	target.resist = 100

	_expect_equal(target._calculate_damage(100, Attack.AttackType.PHYSICAL), 50, "100 defense halves physical damage")
	_expect_equal(target._calculate_damage(100, Attack.AttackType.MAGICAL), 50, "100 resist halves magical damage")
	_expect_equal(target._calculate_damage(4, Attack.AttackType.PHYSICAL), 2, "rounded damage uses percentage mitigation")
	_expect_equal(target._calculate_damage(0, Attack.AttackType.PHYSICAL), 0, "zero-damage attacks do not deal negative damage")
