extends Resource
class_name Reward

@export var experience := 0
@export var gold := 0
@export var items: Array[String] = []

@export_group("Random Weapon")
@export var random_weapon: bool = false
@export var rarity: Item.Rarity

func get_description() -> String:
	var description := "Reward:\n  XP: %d\n  Gold: %d"
	for item in items:
		description += ("\n  " + item)
	if random_weapon:
		description += "\n  Random %s weapon" % Item.rarity_to_string(rarity)
	return description
