extends RefCounted
class_name RewardService

static func grant(reward: Reward, recipient: Hero, party: Party = null) -> Array[RewardEntry]:
	var entries: Array[RewardEntry] = []
	party = _resolve_party(party if party != null else recipient)
	if reward == null or recipient == null or party == null:
		push_warning("RewardService: reward, recipient, and party are required")
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
		member.gain_experience(amount) # full amount each, like battle XP
	return RewardEntry.experience(amount)

static func grant_party_member(target: Variant, hero_class: Hero.HeroClass, level: int = 1) -> RewardEntry:
	var party := _resolve_party(target)
	var hero := HeroLoader.new_hero(hero_class)
	if party == null or hero == null:
		return null
	hero.set_level(level)
	if not party.add_member(hero):
		return null
	return RewardEntry.party_member(hero.name, hero.level)

static func grant_random_party_weapon(target: Variant, rarity: Item.Rarity) -> RewardEntry:
	var party := _resolve_party(target)
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

static func grant_experience(recipient: Hero, amount: int) -> RewardEntry:
	if recipient == null or amount <= 0:
		return null
	recipient.gain_experience(amount)
	return RewardEntry.experience(amount)

static func grant_gold(target: Variant, amount: int) -> RewardEntry:
	var party := _resolve_party(target)
	if party == null or amount <= 0:
		return null
	party.inventory.gold += amount
	return RewardEntry.gold(amount)

static func grant_item(target: Variant, item_id: String, amount: int = 1) -> RewardEntry:
	var party := _resolve_party(target)
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

static func grant_loot(loot: Dictionary, target: Variant, weapon_class: Variant = null) -> Array[RewardEntry]:
	var entries: Array[RewardEntry] = []
	var party := _resolve_party(target)
	if weapon_class == null and target is Hero:
		weapon_class = (target as Hero).hero_class
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
		_append_entry(entries, grant_random_weapon(party, weapon_class, rarity))
	return entries

static func grant_potion(target: Variant, item_id: String, amount: int) -> RewardEntry:
	var party := _resolve_party(target)
	if party == null or amount <= 0:
		return null
	var potion := ItemLoader.get_item(item_id) as Potion
	if potion == null:
		push_warning("RewardService: unknown potion id '%s'" % item_id)
		return null
	party.inventory.add_potion(item_id, amount)
	return RewardEntry.potion(item_id, amount)

static func grant_weapon(target: Variant, weapon_id: String) -> RewardEntry:
	var party := _resolve_party(target)
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

static func grant_random_weapon(target: Variant, hero_class_or_rarity: Variant, rarity: Variant = null) -> RewardEntry:
	var party := _resolve_party(target)
	var hero_class: Hero.HeroClass
	if rarity == null and target is Hero:
		hero_class = (target as Hero).hero_class
		rarity = hero_class_or_rarity
	else:
		hero_class = hero_class_or_rarity
	if party == null:
		return null
	var class_weapons: Dictionary = WeaponDatabase.CLASS_WEAPON_TABLE.get(hero_class, {})
	var candidates: Array = class_weapons.get(rarity, [])
	candidates = candidates.filter(func(weapon_id: String) -> bool: return not party.has_weapon(weapon_id))
	var weapon_id: String = "" if candidates.is_empty() else candidates[randi() % candidates.size()]
	if weapon_id.is_empty():
		var fallback_gold := WeaponDatabase.get_gold_fallback_for_rarity(rarity)
		party.inventory.gold += fallback_gold
		return RewardEntry.weapon_fallback(fallback_gold)
	return grant_weapon(party, weapon_id)

static func _resolve_party(target: Variant) -> Party:
	if target is Party:
		return target as Party
	if target is Hero:
		var hero := target as Hero
		if GameState.party != null and GameState.party.has_member(hero):
			return GameState.party
		push_error("RewardService: Hero recipient must belong to the persistent Party.")
	return null

static func _append_entry(entries: Array[RewardEntry], entry: RewardEntry) -> void:
	if entry != null:
		entries.append(entry)
