extends Resource
class_name Inventory

@export var gold: int = 0
@export var equipped_weapon: Weapon
@export var weapon_stash: Array[String]
@export var potions: Dictionary = {}
@export var quest_items: Dictionary = {}

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

func get_potion_count(item_id: String) -> int:
	return int(potions.get(item_id, 0))

func remove_potions(item_id: String, amount: int) -> bool:
	if amount <= 0 or get_potion_count(item_id) < amount:
		return false
	potions[item_id] -= amount
	if potions[item_id] <= 0:
		potions.erase(item_id)
	return true

# ================================================
#  Quest Items
# ================================================
func add_quest_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	quest_items[item_id] = int(quest_items.get(item_id, 0)) + amount

func get_quest_item_count(item_id: String) -> int:
	return int(quest_items.get(item_id, 0))

func remove_quest_items(item_id: String, amount: int) -> bool:
	if amount <= 0 or get_quest_item_count(item_id) < amount:
		return false
	quest_items[item_id] -= amount
	if quest_items[item_id] <= 0:
		quest_items.erase(item_id)
	return true

func get_item_count(item_id: String) -> int:
	var item := ItemLoader.get_item(item_id)
	if item is Potion:
		return get_potion_count(item_id)
	if item is QuestItem:
		return get_quest_item_count(item_id)
	if item is Weapon:
		return 1 if item_id in weapon_stash else 0
	return 0

func remove_items(item_id: String, amount: int) -> bool:
	var item := ItemLoader.get_item(item_id)
	if item is Potion:
		return remove_potions(item_id, amount)
	if item is QuestItem:
		return remove_quest_items(item_id, amount)
	if item is Weapon and amount == 1 and item_id in weapon_stash:
		weapon_stash.erase(item_id)
		return true
	return false

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
