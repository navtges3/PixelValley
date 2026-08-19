extends RefCounted
class_name RewardService

static func grant(reward: Reward, recipient: Hero) -> Array[RewardEntry]:
	var entries: Array[RewardEntry] = []
	if reward == null or recipient == null:
		push_warning("RewardService: reward and recipient are required")
		return entries
	_append_entry(entries, grant_experience(recipient, reward.experience))
	_append_entry(entries, grant_gold(recipient, reward.gold))
	for item_id in reward.items:
		_append_entry(entries, grant_item(recipient, item_id, 1))
	if reward.random_weapon:
		_append_entry(entries, grant_random_weapon(recipient, reward.rarity))
	return entries

static func grant_experience(recipient: Hero, amount: int) -> RewardEntry:
	if recipient == null or amount <= 0:
		return null
	recipient.gain_experience(amount)
	return RewardEntry.experience(amount)

static func grant_gold(recipient: Hero, amount: int) -> RewardEntry:
	if recipient == null or amount <= 0:
		return null
	recipient.inventory.gold += amount
	return RewardEntry.gold(amount)

static func grant_item(recipient: Hero, item_id: String, amount: int = 1) -> RewardEntry:
	if recipient == null or amount <= 0:
		return null
	var item := ItemLoader.get_item(item_id)
	if item is Potion:
		return grant_potion(recipient, item_id, amount)
	if item is Weapon:
		if amount != 1:
			push_warning("RewardService: weapon '%s' quantity must be exactly one" % item_id)
			return null
		return grant_weapon(recipient, item_id)
	if item is QuestItem:
		recipient.inventory.add_quest_item(item_id, amount)
		return RewardEntry.quest_item(item_id, amount)
	push_warning("RewardService: unknown item id '%s'" % item_id)
	return null

static func grant_loot(loot: Dictionary, recipient: Hero) -> Array[RewardEntry]:
	var entries: Array[RewardEntry] = []
	if recipient == null:
		push_warning("RewardService: loot recipient is required")
		return entries
	_append_entry(entries, grant_gold(recipient, int(loot.get("gold", 0))))
	var items: Dictionary = loot.get("items", {})
	for item_id: String in items:
		var amount: int = int(items[item_id])
		var item: Item = ItemLoader.get_item(item_id)
		if item == null:
			push_warning("RewardService: unknown item id '%s'" % item_id)
			continue
		if item is Weapon:
			if amount <= 0:
				continue
			if amount > 1:
				push_warning("RewardService: weapon '%s' quantity was limited to one" % item_id)
			_append_entry(entries, grant_weapon(recipient, item_id))
			continue
		_append_entry(entries, grant_item(recipient, item_id, amount))
	if bool(loot.get("random_weapon", false)):
		var rarity: Item.Rarity = loot.get("weapon_rarity", Item.Rarity.COMMON)
		_append_entry(entries, grant_random_weapon(recipient, rarity))
	return entries

static func grant_potion(recipient: Hero, item_id: String, amount: int) -> RewardEntry:
	if recipient == null or amount <= 0:
		return null
	var potion := ItemLoader.get_item(item_id) as Potion
	if potion == null:
		push_warning("RewardService: unknown potion id '%s'" % item_id)
		return null
	recipient.inventory.add_potion(item_id, amount)
	return RewardEntry.potion(item_id, amount)

static func grant_weapon(recipient: Hero, weapon_id: String) -> RewardEntry:
	if recipient == null:
		return null
	var weapon := ItemLoader.get_item(weapon_id) as Weapon
	if weapon == null:
		push_warning("RewardService: unknown weapon id '%s'" % weapon_id)
		return null
	if recipient.inventory.has_weapon_in_stash(weapon_id):
		var gold := weapon.value
		recipient.inventory.gold += gold
		return RewardEntry.weapon_sold(weapon_id, gold)
	recipient.inventory.add_weapon_to_stash(weapon_id)
	return RewardEntry.weapon(weapon_id)

static func grant_random_weapon(recipient: Hero, rarity: Item.Rarity) -> RewardEntry:
	if recipient == null:
		return null
	var weapon_id := WeaponDatabase.get_random_unowned_weapon_id_for_class(recipient.hero_class, rarity, recipient.inventory)
	if weapon_id.is_empty():
		var fallback_gold := WeaponDatabase.get_gold_fallback_for_rarity(rarity)
		recipient.inventory.gold += fallback_gold
		return RewardEntry.weapon_fallback(fallback_gold)
	return grant_weapon(recipient, weapon_id)

static func _append_entry(entries: Array[RewardEntry], entry: RewardEntry) -> void:
	if entry != null:
		entries.append(entry)
