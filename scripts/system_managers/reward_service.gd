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

# Battle XP only goes to whoever fought, so this stays hero-scoped —
# it's the hero's own stat, not something living in party inventory.
static func grant_experience(hero: Hero, amount: int) -> RewardEntry:
	if hero == null or amount <= 0:
		return null
	hero.gain_experience(amount)
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
		var gold := WeaponDatabase.get_gold_fallback_for_rarity(rarity)
		party.inventory.gold += gold
		return RewardEntry.weapon_fallback(gold)
	return grant_weapon(party, candidates.pick_random())

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
