extends Node

enum MonsterID {
	GOBLIN_SCOUT, GOBLIN_ARCHER, GOBLIN_BRUTE, GOBLIN_SHAMAN, FOREST_GOBLIN,
	ORC_GRUNT, ORC_ARCHER, ORC_BERSERKER, ORC_SHAMAN, ORC_SPEARMAN, ORC_CAPTAIN, ORC_SHIELDBEARER,
	ORC_CHIEFTAIN,
	OGRE_BRUTE, OGRE_GUARD, OGRE_SHAMAN, CAVE_TROLL, CAVE_BEAST, STONE_GOLEM,
	OGRE_WARLORD,
	OGRE_KING,
}

var monster_paths: Dictionary = {
	MonsterID.GOBLIN_SCOUT: "res://resources/characters/monsters/goblin_scout.tres",
	MonsterID.GOBLIN_ARCHER: "res://resources/characters/monsters/goblin_archer.tres",
	MonsterID.GOBLIN_BRUTE: "res://resources/characters/monsters/goblin_brute.tres",
	MonsterID.GOBLIN_SHAMAN: "res://resources/characters/monsters/goblin_shaman.tres",
	MonsterID.FOREST_GOBLIN: "res://resources/characters/monsters/forest_goblin.tres",
	MonsterID.ORC_GRUNT: "res://resources/characters/monsters/orc_grunt.tres",
	MonsterID.ORC_ARCHER: "res://resources/characters/monsters/orc_archer.tres",
	MonsterID.ORC_BERSERKER: "res://resources/characters/monsters/orc_berserker.tres",
	MonsterID.ORC_SHAMAN: "res://resources/characters/monsters/orc_shaman.tres",
	MonsterID.ORC_SPEARMAN: "res://resources/characters/monsters/orc_spearman.tres",
	MonsterID.ORC_CAPTAIN: "res://resources/characters/monsters/orc_captain.tres",
	MonsterID.ORC_SHIELDBEARER: "res://resources/characters/monsters/orc_shieldbearer.tres",
	MonsterID.ORC_CHIEFTAIN: "res://resources/characters/monsters/orc_chieftain/orc_chieftain.tres",
	MonsterID.OGRE_BRUTE: "res://resources/characters/monsters/ogre_brute.tres",
	MonsterID.OGRE_GUARD: "res://resources/characters/monsters/ogre_guard.tres",
	MonsterID.OGRE_SHAMAN: "res://resources/characters/monsters/ogre_shaman.tres",
	MonsterID.CAVE_TROLL: "res://resources/characters/monsters/cave_troll.tres",
	MonsterID.CAVE_BEAST: "res://resources/characters/monsters/cave_beast.tres",
	MonsterID.STONE_GOLEM: "res://resources/characters/monsters/stone_golem.tres",
	MonsterID.OGRE_WARLORD: "res://resources/characters/monsters/ogre_warlord/ogre_warlord.tres",
	MonsterID.OGRE_KING: "res://resources/characters/monsters/ogre_king/ogre_king.tres",
}

func new_monster(monster_id: MonsterID) -> Monster:
	if not monster_paths.has(monster_id):
		push_error("MONSTER '%s' not found." % monster_id)
		return null
	return (load(monster_paths[monster_id]) as Monster).duplicate(true)

func get_monster_name(monster_id: MonsterID) -> String:
	if not monster_paths.has(monster_id):
		return "Unknown Monster"
	return (load(monster_paths[monster_id]) as Monster).name
