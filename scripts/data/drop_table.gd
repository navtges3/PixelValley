extends Resource
class_name DropTable

@export var entries: Array[DropEntry] = []
@export var weapon_chance: float = 0.0
@export var weapon_rarity: Item.Rarity = Item.Rarity.COMMON

func roll(hero_class: Hero.HeroClass) -> Dictionary:
	var results := {
		"potions": {},
		"weapon_id": "",
		"gold": 0
	}
	for entry in entries:
		var roll_result := entry.roll()
		if roll_result.is_empty():
			continue
		var item_id: String = roll_result[0]
		var count: int = roll_result[1]
		var item := ItemLoader.get_item(item_id)
		if item is Potion:
			results["potions"][item_id] = results["potions"].get(item_id, 0) + count
		elif item is Weapon:
			if results["weapon_id"] == "":
				results["weapon_id"] = item_id
	if weapon_chance > 0.0 and randf() <= weapon_chance:
		var weapon_id := WeaponDatabase.get_random_unowned_weapon_id_for_class(hero_class, weapon_rarity)
		if weapon_id != "" and results["weapon_id"] == "":
			results["weapon_id"] = weapon_id
	return results
