extends Resource
class_name Inventory

@export var gold: int = 0
@export var equipped_weapon: Weapon
@export var weapon_stash: Array[String]
@export var potions: Dictionary = {}

# ================================================
#  Potions
# ================================================
func use_potion(item_id: String) -> Array[Effect]:
	if not potions.has(item_id):
		return []
	potions[item_id] -= 1
	if potions[item_id] <= 0:
		potions.erase(item_id)
	var potion := ItemLoader.get_item(item_id) as Potion
	return potion.effects if potion else []

func add_potion(item_id: String, amount: int = 1) -> void:
	potions[item_id] = potions.get(item_id, 0) + amount

# ================================================
#  Weapons
# ================================================
func equip_weapon(weapon_id: String) -> void:
	if equipped_weapon:
		var old_id := ItemLoader.get_item_id(equipped_weapon)
		if old_id != "" and old_id not in weapon_stash:
			weapon_stash.append(old_id)
	equipped_weapon = ItemLoader.get_item(weapon_id) as Weapon
	weapon_stash.erase(weapon_id)

func add_weapon_to_stash(weapon_id: String) -> void:
	var equipped_id := ItemLoader.get_item_id(equipped_weapon)
	if weapon_id not in weapon_stash and weapon_id != equipped_id:
		weapon_stash.append(weapon_id)
	else:
		gold += (ItemLoader.get_item(weapon_id) as Weapon).value

func has_weapon_in_stash(item_id: String) -> bool:
	if equipped_weapon != null and ItemLoader.get_item_id(equipped_weapon) == item_id:
		return true
	return item_id in weapon_stash

func remove_weapon_from_stash(weapon_id: String) -> void:
	weapon_stash.erase(weapon_id)
