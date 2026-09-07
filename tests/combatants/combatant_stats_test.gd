extends TestCase

const HERO_RESOURCES := [
	"res://resources/characters/heroes/assassin/assassin.tres",
	"res://resources/characters/heroes/knight/knight.tres",
	"res://resources/characters/heroes/princess/princess.tres",
]

const MONSTER_RESOURCES := [
	"res://resources/characters/monsters/goblin/goblin.tres",
	"res://resources/characters/monsters/orc/orc.tres",
	"res://resources/characters/monsters/orc_chieftain/orc_chieftain.tres",
	"res://resources/characters/monsters/ogre/ogre.tres",
	"res://resources/characters/monsters/ogre_warlord/ogre_warlord.tres",
	"res://resources/characters/monsters/ogre_king/ogre_king.tres",
]


func run_tests() -> int:
	_begin_test_run()
	_test_default_initiative()
	_test_resource_initiative_values()
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
