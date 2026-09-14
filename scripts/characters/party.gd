extends Resource
class_name Party

const MAX_MEMBERS := 4

@export var members: Array[Hero] = []
@export var inventory: Inventory = Inventory.new():
	set(value):
		inventory = value if value != null else Inventory.new()
		for member: Hero in members:
			member.inventory = inventory

func add_member(hero: Hero) -> bool:
	if hero == null or hero in members or members.size() >= MAX_MEMBERS:
		return false
	members.append(hero)
	hero.inventory = inventory
	_remove_equipped_weapon_from_stash(hero)
	return true

func has_member(hero: Hero) -> bool:
	return hero != null and hero in members

func has_weapon(weapon_id: String) -> bool:
	if weapon_id in inventory.weapon_stash:
		return true
	for hero: Hero in members:
		if _get_equipped_weapon_id(hero) == weapon_id:
			return true
	return false

func create_battle_party() -> BattleParty:
	var battle_party := BattleParty.new()
	for member: Hero in members:
		battle_party.add_member(member)
	return battle_party

func equip_weapon(hero: Hero, weapon_id: String) -> bool:
	if not has_member(hero) or weapon_id not in inventory.weapon_stash:
		return false
	var weapon_template := ItemLoader.get_item(weapon_id) as Weapon
	if weapon_template == null:
		return false
	var previous_weapon_id := _get_equipped_weapon_id(hero)
	if previous_weapon_id == weapon_id:
		return false
	inventory.weapon_stash.erase(weapon_id)
	hero.equipped_weapon = weapon_template.duplicate(true) as Weapon
	if not previous_weapon_id.is_empty() and previous_weapon_id not in inventory.weapon_stash:
		inventory.weapon_stash.append(previous_weapon_id)
	return true

func unequip_weapon(hero: Hero) -> bool:
	if not has_member(hero) or hero.equipped_weapon == null:
		return false
	var weapon_id := _get_equipped_weapon_id(hero)
	if weapon_id.is_empty():
		return false
	hero.equipped_weapon = null
	if weapon_id not in inventory.weapon_stash:
		inventory.weapon_stash.append(weapon_id)
	return true

func _remove_equipped_weapon_from_stash(hero: Hero) -> void:
	var equipped_id := _get_equipped_weapon_id(hero)
	if equipped_id.is_empty():
		return
	while equipped_id in inventory.weapon_stash:
		inventory.weapon_stash.erase(equipped_id)

func _get_equipped_weapon_id(hero: Hero) -> String:
	if hero == null or hero.equipped_weapon == null or hero.equipped_weapon.name.is_empty():
		return ""
	return ItemLoader.get_item_id(hero.equipped_weapon)
