extends Node

enum MonsterID {
	GOBLIN,
	ORC,
	ORC_CHIEFTAIN,
	OGRE,
	OGRE_WARLORD,
	OGRE_KING,
}

var monster_db: Dictionary = {
	MonsterID.GOBLIN: preload("res://resources/characters/monsters/goblin/goblin.tres"),
	MonsterID.ORC: preload("res://resources/characters/monsters/orc/orc.tres"),
	MonsterID.ORC_CHIEFTAIN: preload("res://resources/characters/monsters/orc_chieftain/orc_chieftain.tres"),
	MonsterID.OGRE: preload("res://resources/characters/monsters/ogre/ogre.tres"),
	MonsterID.OGRE_WARLORD: preload("res://resources/characters/monsters/ogre_warlord/ogre_warlord.tres"),
	MonsterID.OGRE_KING: preload("res://resources/characters/monsters/ogre_king/ogre_king.tres"),
}

func get_monster_name(monster_id: MonsterID) -> String:
	if monster_id in monster_db:
		return monster_db[monster_id].name
	else:
		return "Unknown Monster"

func new_monster(monster_id: MonsterID) -> Monster:
	if monster_id in monster_db:
		var monster = monster_db[monster_id].duplicate(true) as Monster
		print("Loading new %s..." % monster.name)
		return monster
	else:
		push_error("Monster '%s' not found in database." % monster_id)
		return null
