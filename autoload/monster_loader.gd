extends Node

enum MonsterID {
	GOBLIN,
	ORC,
	ORC_CHIEFTAIN,
	OGRE,
	OGRE_WARLORD,
	OGRE_KING,
}

var monster_paths: Dictionary = {
	MonsterID.GOBLIN: "res://resources/characters/monsters/goblin/goblin.tres",
	MonsterID.ORC: "res://resources/characters/monsters/orc/orc.tres",
	MonsterID.ORC_CHIEFTAIN: "res://resources/characters/monsters/orc_chieftain/orc_chieftain.tres",
	MonsterID.OGRE: "res://resources/characters/monsters/ogre/ogre.tres",
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
