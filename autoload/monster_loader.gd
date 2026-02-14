extends Node

var monster_db: Dictionary = {
	"Goblin": preload("res://resources/monsters/goblin/goblin.tres"),
	"Orc": preload("res://resources/monsters/orc.tres"),
	"Ogre": preload("res://resources/monsters/ogre.tres"),
}

func get_monster(monster_name: String, level: int = 1) -> Monster:
	if monster_name in monster_db:
		var monster = monster_db[monster_name].duplicate() as Monster
		monster.set_level(level)
		return monster
	else:
		push_error("Monster '%s' not found in database." % monster_name)
		return null
