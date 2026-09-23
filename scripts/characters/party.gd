extends Resource
class_name Party

const MAX_ACTIVE_MEMBERS := 4

signal party_changed

@export var members: Array[Hero] = []
@export var active_member_ids: Array[StringName] = []
@export var inventory: Inventory = Inventory.new():
	set(value):
		inventory = value if value != null else Inventory.new()

# ---- PARTY ----
func add_member(hero: Hero) -> bool:
	if hero == null or has_member(hero):
		return false
	_assign_hero_id(hero)
	members.append(hero)
	if active_member_ids.size() < MAX_ACTIVE_MEMBERS:
		active_member_ids.append(hero.hero_id)
	_remove_equipped_weapon_from_stash(hero)
	party_changed.emit()
	return true

func add_to_active_party(hero: Hero) -> bool:
	if not is_eligible(hero) or active_member_ids.size() >= MAX_ACTIVE_MEMBERS:
		return false
	if hero.hero_id in active_member_ids:
		return false
	active_member_ids.append(hero.hero_id)
	return true

func remove_from_active_party(hero: Hero) -> bool:
	if not has_member(hero) or hero.hero_id not in active_member_ids:
		return false
	if is_leader(hero) or active_member_ids.size() <= 1:
		return false
	active_member_ids.erase(hero.hero_id)
	return true

func has_member(hero: Hero) -> bool:
	return hero != null and hero in members

func get_active_members() -> Array[Hero]:
	var result: Array[Hero] = []
	for hero_id: StringName in active_member_ids:
		var hero := get_member_by_id(hero_id)
		if hero != null:
			result.append(hero)
	return result

func get_member_by_id(hero_id: StringName) -> Hero:
	for hero: Hero in members:
		if hero.hero_id == hero_id:
			return hero
	return null

func set_active_member_ids(ids: Array) -> void:
	active_member_ids.clear()
	for raw_id in ids:
		var hero_id := StringName(str(raw_id))
		if hero_id.is_empty() or hero_id in active_member_ids:
			continue
		if get_member_by_id(hero_id) == null:
			continue
		active_member_ids.append(hero_id)
		if active_member_ids.size() >= MAX_ACTIVE_MEMBERS:
			break
	party_changed.emit()

func has_weapon(weapon_id: String) -> bool:
	if weapon_id in inventory.weapon_stash:
		return true
	for hero: Hero in members:
		if _get_equipped_weapon_id(hero) == weapon_id:
			return true
	return false

func create_battle_party() -> BattleParty:
	var battle_party := BattleParty.new()
	for member: Hero in get_eligible_active_members():
		battle_party.add_member(member)
	return battle_party

func rest_all() -> void:
	for hero: Hero in members:
		hero.rest()

func is_leader(hero: Hero) -> bool:
	return not members.is_empty() and members[0] == hero

func is_eligible(hero: Hero) -> bool:
	return has_member(hero) and hero.is_alive()

func get_eligible_active_members() -> Array[Hero]:
	var result: Array[Hero] = []
	for hero: Hero in get_active_members():
		if is_eligible(hero):
			result.append(hero)
	return result

func can_fight() -> bool:
	return not get_eligible_active_members().is_empty()

func move_active_member(hero: Hero, direction: int) -> bool:
	if hero == null:
		return false
	var index := active_member_ids.find(hero.hero_id)
	var target := index + direction
	if index == -1 or target < 0 or target >= active_member_ids.size():
		return false
	active_member_ids.remove_at(index)
	active_member_ids.insert(target, hero.hero_id)
	party_changed.emit()
	return true

# ---- INVENTORY ----
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
	party_changed.emit()
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
	party_changed.emit()
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

func _assign_hero_id(hero: Hero) -> void:
	if not hero.hero_id.is_empty() and get_member_by_id(hero.hero_id) == null:
		return
	var index := members.size()
	var candidate := StringName("hero_%d" % index)
	while get_member_by_id(candidate) != null:
		index += 1
		candidate = StringName("hero_%d" % index)
	hero.hero_id = candidate
