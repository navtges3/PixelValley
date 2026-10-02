extends RefCounted
class_name RewardService

static func grant(reward: Reward, party: Party) -> Array[RewardEntry]:
	var entries: Array[RewardEntry] = []
	if reward == null or party == null:
		push_warning("RewardService: reward and party are required")
		return entries
	_append_entry(entries, grant_party_experience(party, reward.experience))
	_append_entry(entries, grant_gold(party, reward.gold))
	for item_id in reward.items:
		_append_entry(entries, grant_item(party, item_id, 1))
	if reward.random_weapon:
		_append_entry(entries, grant_random_party_weapon(party, reward.rarity))
	if reward.recruit_hero: # last, so the recruit gets no quest XP
		var level := reward.recruit_level
		if reward.recruit_level_mode == Reward.RecruitLevelMode.PARTY_AVERAGE:
			level = party.get_average_level() # before she joins
		_append_entry(entries, grant_party_member(party, reward.recruit_hero_class, level))
	return entries

static func grant_party_experience(party: Party, amount: int) -> RewardEntry:
	if party == null or amount <= 0:
		return null
	for member: Hero in party.members:
		member.gain_experience(amount)
	return RewardEntry.experience(amount)

static func grant_party_member(party: Party, hero_class: Hero.HeroClass, level: int = 1) -> RewardEntry:
	if party == null:
		return null
	var hero := HeroLoader.new_hero(hero_class)
	if hero == null:
		return null
	hero.set_level(level)
	if not party.add_member(hero):
		return null
	return RewardEntry.party_member(hero.name, hero.level)

static func grant_random_party_weapon(party: Party, rarity: Item.Rarity) -> RewardEntry:
	if party == null:
		return null
	var weapon_id := _pick_random_party_weapon_id(party, rarity)
	if weapon_id.is_empty():
		var gold := WeaponDatabase.get_gold_fallback_for_rarity(rarity)
		party.inventory.gold += gold
		return RewardEntry.weapon_fallback(gold)
	return grant_weapon(party, weapon_id)

static func _pick_random_party_weapon_id(party: Party, rarity: Item.Rarity) -> String:
	if party == null:
		return ""
	var candidates: Array[String] = []
	var seen: Dictionary = {}
	for member: Hero in party.members:
		if seen.has(member.hero_class):
			continue
		seen[member.hero_class] = true
		var by_rarity: Dictionary = WeaponDatabase.CLASS_WEAPON_TABLE.get(member.hero_class, {})
		for weapon_id: String in by_rarity.get(rarity, []):
			if not party.has_weapon(weapon_id) and not candidates.has(weapon_id):
				candidates.append(weapon_id)
	if candidates.is_empty():
		return ""
	return candidates.pick_random()

static func grant_battle_rewards(
	monsters: Array[Monster],
	recipients: Array[Hero],
	party: Party
) -> Array[RewardEntry]:
	var entries: Array[RewardEntry] = []
	if party == null:
		push_warning("RewardService: battle reward party is required")
		return entries

	var total_xp := 0
	var total_gold := 0
	var combined_items: Dictionary[String, int] = {}
	var authored_weapon_ids: Array[String] = []
	var random_weapon_rarities: Array[Item.Rarity] = []
	for monster: Monster in monsters:
		total_xp += monster.calculate_experience()
		total_gold += monster.calculate_gold()
		var loot := monster.roll_loot()
		total_gold += int(loot.get("gold", 0))
		var items: Dictionary = loot.get("items", {})
		for item_id: String in items:
			var amount := int(items[item_id])
			var item: Item = ItemLoader.get_item(item_id)
			if item is Weapon:
				if amount <= 0:
					continue
				if amount > 1:
					push_warning("RewardService: weapon '%s' quantity was limited to one" % item_id)
				authored_weapon_ids.append(item_id)
			else:
				combined_items[item_id] = int(combined_items.get(item_id, 0)) + amount
		if bool(loot.get("random_weapon", false)):
			var rarity: Item.Rarity = loot.get("weapon_rarity", Item.Rarity.COMMON)
			random_weapon_rarities.append(rarity)

	if total_xp > 0:
		for recipient: Hero in recipients:
			recipient.gain_experience(total_xp)
		_append_entry(entries, RewardEntry.experience(total_xp))

	var weapon_entries: Array[RewardEntry] = []
	for weapon_id: String in authored_weapon_ids:
		total_gold += _grant_battle_weapon(party, weapon_id, weapon_entries)
	for rarity: Item.Rarity in random_weapon_rarities:
		var weapon_id := _pick_random_party_weapon_id(party, rarity)
		if weapon_id.is_empty():
			total_gold += WeaponDatabase.get_gold_fallback_for_rarity(rarity)
		else:
			total_gold += _grant_battle_weapon(party, weapon_id, weapon_entries)

	var item_entries: Array[RewardEntry] = []
	for item_id: String in combined_items:
		if ItemLoader.get_item(item_id) == null:
			push_warning("RewardService: unknown item id '%s'" % item_id)
			continue
		_append_entry(item_entries, grant_item(party, item_id, combined_items[item_id]))

	_append_entry(entries, grant_gold(party, total_gold))
	for entry: RewardEntry in item_entries:
		_append_entry(entries, entry)
	for entry: RewardEntry in weapon_entries:
		_append_entry(entries, entry)
	return entries

static func _grant_battle_weapon(
	party: Party,
	weapon_id: String,
	weapon_entries: Array[RewardEntry]
) -> int:
	var weapon := ItemLoader.get_item(weapon_id) as Weapon
	if weapon == null:
		push_warning("RewardService: unknown weapon id '%s'" % weapon_id)
		return 0
	if party.has_weapon(weapon_id):
		return weapon.value
	party.inventory.add_weapon(weapon_id)
	_append_entry(weapon_entries, RewardEntry.weapon(weapon_id))
	return 0

static func grant_gold(party: Party, amount: int) -> RewardEntry:
	if party == null or amount <= 0:
		return null
	party.inventory.gold += amount
	return RewardEntry.gold(amount)

static func grant_item(party: Party, item_id: String, amount: int = 1) -> RewardEntry:
	if party == null or amount <= 0:
		return null
	var item := ItemLoader.get_item(item_id)
	if item is Potion:
		return grant_potion(party, item_id, amount)
	if item is Weapon:
		if amount != 1:
			push_warning("RewardService: weapon '%s' quantity must be exactly one" % item_id)
			return null
		return grant_weapon(party, item_id)
	if item is QuestItem:
		party.inventory.add_quest_item(item_id, amount)
		return RewardEntry.quest_item(item_id, amount)
	push_warning("RewardService: unknown item id '%s'" % item_id)
	return null

static func grant_loot(loot: Dictionary, party: Party) -> Array[RewardEntry]:
	var entries: Array[RewardEntry] = []
	if party == null:
		push_warning("RewardService: loot party is required")
		return entries
	_append_entry(entries, grant_gold(party, int(loot.get("gold", 0))))
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
			_append_entry(entries, grant_weapon(party, item_id))
			continue
		_append_entry(entries, grant_item(party, item_id, amount))
	if bool(loot.get("random_weapon", false)):
		var rarity: Item.Rarity = loot.get("weapon_rarity", Item.Rarity.COMMON)
		_append_entry(entries, grant_random_party_weapon(party, rarity))
	return entries

static func grant_potion(party: Party, item_id: String, amount: int) -> RewardEntry:
	if party == null or amount <= 0:
		return null
	var potion := ItemLoader.get_item(item_id) as Potion
	if potion == null:
		push_warning("RewardService: unknown potion id '%s'" % item_id)
		return null
	party.inventory.add_potion(item_id, amount)
	return RewardEntry.potion(item_id, amount)

static func grant_weapon(party: Party, weapon_id: String) -> RewardEntry:
	if party == null:
		return null
	var weapon := ItemLoader.get_item(weapon_id) as Weapon
	if weapon == null:
		push_warning("RewardService: unknown weapon id '%s'" % weapon_id)
		return null
	if party.has_weapon(weapon_id):
		var gold := weapon.value
		party.inventory.gold += gold
		return RewardEntry.weapon_sold(weapon_id, gold)
	party.inventory.add_weapon(weapon_id)
	return RewardEntry.weapon(weapon_id)

static func _append_entry(entries: Array[RewardEntry], entry: RewardEntry) -> void:
	if entry != null:
		entries.append(entry)
