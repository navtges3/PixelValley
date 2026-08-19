extends Resource
class_name DropTable

@export var entries: Array[DropEntry] = []

@export_group("Gold")
@export var min_gold: int = 0
@export var max_gold: int = 0

@export_group("Random Weapon")
@export var weapon_chance: float = 0.0
@export var weapon_rarity: Item.Rarity = Item.Rarity.COMMON

func roll() -> Dictionary:
	var items: Dictionary[String, int] = {}
	for entry: DropEntry in entries:
		var roll_result: Array = entry.roll()
		if roll_result.is_empty():
			continue
		var item_id: String = roll_result[0]
		var count: int = roll_result[1]
		var item: Item = ItemLoader.get_item(item_id)
		if item == null:
			push_warning("DropTable: unknown item id '%s'" % item_id)
			continue
		if item is Weapon:
			if count != 1:
				push_warning("DropTable: weapon '%s' quantity was limited to one" % item_id)
			items[item_id] = 1
			continue
		items[item_id] = items.get(item_id, 0) + count
	var gold_low: int = maxi(0, min_gold)
	var gold_high: int = maxi(gold_low, max_gold)
	var gold_amount: int = randi_range(gold_low, gold_high)
	return {
		"items": items,
		"gold": gold_amount,
		"random_weapon": (
			weapon_chance > 0.0
			and randf() < clampf(weapon_chance, 0.0, 1.0)
		),
		"weapon_rarity": weapon_rarity,
	}
