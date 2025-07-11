extends Node

var potion_dictionary = {
	"Health Potion": "Health Potion",
	"Block Potion": "Block Potion",
	"Damage Potion": "Damage Potion"
}

var quest_list: Array[Quest] = []

func _create_default_quests():
	quest_list = [
		Quest.new().init_quest("Village Under Siege", "Defend the villagers by eliminating four goblins and two orcs.",
			{"Goblin": 4, "Orc": 2}, potion_dictionary["Block Potion"], {"village": 10}),
		Quest.new().init_quest("Goblin Infestation", "A horde of goblins threatens the farms! Defeat six goblins.",
			{"Goblin": 6}, potion_dictionary["Health Potion"], {"village": 10}),
		Quest.new().init_quest("Ogre Troubles", "Ogres have taken control of the mines. Slay three to reclaim the tunnels!",
			{"Ogre": 3}, potion_dictionary["Damage Potion"], {"village": 10}),
		Quest.new().init_quest("Bridge of Peril", "A goblin warband and their ogre leader guard the bridge. Eliminate them and restore safe passage.",
			{"Goblin": 3, "Ogre": 1}, potion_dictionary["Block Potion"], {"village": 10}),
		Quest.new().init_quest("The Forest Menace", "Patrol the woods and eliminate five goblins and their ogre brute.",
			{"Goblin": 5, "Ogre": 1}, potion_dictionary["Health Potion"], {"village": 10}),
		Quest.new().init_quest("Guardian of the Ruins", "The ruins hold secrets, but goblins and ogres stand in your way. Defeat them!",
			{"Goblin": 2, "Ogre": 2}, potion_dictionary["Damage Potion"], {"village": 10}),
		Quest.new().init_quest("Rampaging Goblins", "A large group of goblins terrorizes the countryside. Take down seven!",
			{"Goblin": 7}, potion_dictionary["Block Potion"], {"village": 10}),
		Quest.new().init_quest("Cave Dweller's Wrath", "Deep in the caves, ogres and goblins lurk. Destroy two goblins and four ogres.",
			{"Goblin": 2, "Ogre": 4}, potion_dictionary["Damage Potion"], {"village": 10}),
		Quest.new().init_quest("Battle at Dawn", "A mixed force of goblins, ogres, and orcs is preparing for an assault. Strike first!",
			{"Goblin": 3, "Ogre": 2, "Orc": 2}, potion_dictionary["Block Potion"], {"village": 10}),
		Quest.new().init_quest("End of the Horde", "Wipe out the remaining goblin forces, their ogre champions, and the orc warlord!",
			{"Goblin": 6, "Ogre": 3, "Orc": 1}, potion_dictionary["Health Potion"], {"village": 10}),
	]

func new_game() -> void:
	quest_list.clear()
	_create_default_quests()

func get_quests_by_type(status: String) -> Array:
	match status:
		"available":
			return quest_list.filter(func(q: Quest): return not q.completed and not q.failed)
		"complete":
			return quest_list.filter(func(q: Quest): return q.completed)
		"failed":
			return quest_list.filter(func(q: Quest): return q.failed)
		_:
			return []

func get_save_data() -> Array:
	var data := []
	for quest in quest_list:
		data.append(quest.get_save_data())
	return data

func load_from_data(data: Array) -> void:
	quest_list.clear()
	for quest_data in data:
		var quest = Quest.new()
		quest.load_from_data(quest_data)
		quest_list.append(quest)


