extends Node
class_name SaveManager

const SAVE_DIR := "user://saves"
const MAX_SLOTS := 3

# ---------------------------------------------------------
# PATH HELPERS
# ---------------------------------------------------------
static func get_slot_dir(slot: int = 1) -> String:
	var saves_dir := ProjectSettings.globalize_path(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(saves_dir)
	return saves_dir.path_join("slot_%d" % slot)

static func _file(slot: int, filename: String) -> String:
	return get_slot_dir(slot).path_join(filename)

# ---------------------------------------------------------
# BASIC API
# ---------------------------------------------------------
static func has_save_data(slot: int = 1) -> bool:
	var dir := get_slot_dir(slot)
	return FileAccess.file_exists(dir.path_join("meta.json"))

static func save_game() -> void:
	var save_slot = GameState.save_slot

	_save_json(save_slot, "hero.json", {
		"data": _get_hero_data(GameState.hero)
	})

	_save_json(save_slot, "village.json", {
		"data": _get_village_data(GameState.village)
	})

	_save_json(save_slot, "quests.json", {
		"data": _get_quests_data(GameState.quest_manager)
	})

	_save_json(save_slot, "meta.json", {
		"hero_name": GameState.hero.name,
		"level": GameState.hero.level,
		"time": Time.get_datetime_string_from_system()
	})

	print("SaveManager: Saved game to slot %d" % save_slot)

static func load_game(save_slot: int = 1) -> void:
	GameState.save_slot = save_slot

	if not has_save_data(save_slot):
		push_error("SaveManager: no save data found for slot %d" % save_slot)
		return

	var hero_json := _load_json(save_slot, "hero.json")
	GameState.hero = _load_hero(hero_json.get("data", {}))

	var village_json := _load_json(save_slot, "village.json")
	GameState.village = _load_village(village_json.get("data", {}))

	var quest_json := _load_json(save_slot, "quests.json")
	GameState.quest_manager = _load_quests(quest_json.get("data", {}))

	print("SaveManager: Loaded game from slot %d" % save_slot)

static func get_save_meta(slot: int = 1) -> Dictionary:
	var meta_json := _load_json(slot, "meta.json")
	return meta_json

# ---------------------------------------------------------
# LOW-LEVEL JSON HANDLING
# ---------------------------------------------------------
static func _save_json(slot: int, filename: String, data: Dictionary) -> void:
	var dir:= get_slot_dir(slot)
	DirAccess.make_dir_recursive_absolute(dir)

	var file := FileAccess.open(dir.path_join(filename), FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to write %s" % filename)
		return

	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()

static func _load_json(slot: int, filename: String) -> Dictionary:
	var path := _file(slot, filename)
	if not FileAccess.file_exists(path):
		push_error("SaveManager: Missing file: %s" % filename)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var result = JSON.parse_string(text)
	if typeof(result) != TYPE_DICTIONARY:
		push_error("SaveManager: Invalid JSON in %s" % filename)
		return {}

	return result

# ---------------------------------------------------------
# HERO SERIALIZATION
# ---------------------------------------------------------
static func _get_hero_data(hero: Hero) -> Dictionary:
	return {
		"hero_name": hero.name,
		"portrait": hero.portrait.resource_path,
		"hero_class": hero.hero_class,
		"level": hero.level,
		"experience": hero.experience,
		"skill_points": hero.skill_points,

		"active_effects": _get_active_effects_data(hero),
		"stat_block": _get_stat_block_data(hero.stat_block),
		"inventory": _get_inventory_data(hero.inventory)
	}

static func _load_hero(data: Dictionary) -> Hero:
	var hero := Hero.new()

	hero.name = data.get("hero_name", "Unnamed Hero")

	var portrait_path = data.get("portrait", "")
	if portrait_path != "":
		hero.portrait = load(portrait_path)

	hero.hero_class = data.get("hero_class", Hero.HeroClass.KNIGHT)
	hero.level = data.get("level", 1)
	hero.experience = data.get("experience", 0)
	hero.skill_points = data.get("skill_points", 0)

	hero.stat_block = _load_stat_block(data.get("stat_block", {}))
	_load_active_effects(data.get("active_effects", []), hero)
	hero.inventory = _load_inventory(data.get("inventory", {}))

	return hero

# ---------------------------------------------------------
# ACTIVE EFFECTS
# ---------------------------------------------------------
static func _get_active_effects_data(combatant: Combatant) -> Array:
	var result := []
	for ae in combatant.active_effects:
		result.append({
			"type": ae.effect.type,
			"strength": ae.effect.strength,
			"duration": ae.effect.duration,
			"remaining_turns": ae.remaining_turns
		})
		ae.on_expire()
	return result

static func _load_active_effects(data: Array, combatant: Combatant) -> void:
	for effect_data in data:
		var effect := Effect.new()
		effect.type = effect_data.get("type", Effect.EffectType.HEAL)
		effect.strength = effect_data.get("strength", 0)
		effect.duration = effect_data.get("duration", 0)

		var remaining = effect_data.get("remaining_turns", 0)
		combatant.apply_effect(effect, null, remaining)

# ---------------------------------------------------------
# STATS
# ---------------------------------------------------------
static func _get_stat_block_data(stat_block: StatBlock) -> Dictionary:
	return {
		"current_hp": stat_block.current_hp,
		"current_nrg": stat_block.current_nrg,
		"max_hp": stat_block.max_hp,
		"max_nrg": stat_block.max_nrg,
		"attack": stat_block.attack,
		"magic": stat_block.magic,
		"defense": stat_block.defense,
		"resistance": stat_block.resistance,
	}

static func _load_stat_block(data: Dictionary) -> StatBlock:
	var stat_block := StatBlock.new()
	stat_block.current_hp = data.get("current_hp", 10)
	stat_block.current_nrg = data.get("current_nrg", 5)
	stat_block.max_hp = data.get("max_hp", 10)
	stat_block.max_nrg = data.get("max_nrg", 5)
	stat_block.attack = data.get("attack", 1)
	stat_block.magic = data.get("magic", 1)
	stat_block.defense = data.get("defense", 1)
	stat_block.resistance = data.get("resistance", 1)
	return stat_block

# ---------------------------------------------------------
# INVENTORY
# ---------------------------------------------------------
static func _get_inventory_data(inventory: Inventory) -> Dictionary:
	var data := {
		"gold": inventory.gold,
		"equipped_weapon": inventory.equipped_weapon.resource_path,
		"weapon_stash": [],
		"potions": []
	}

	for weapon in inventory.weapon_stash:
		data["weapon_stash"].append(weapon.resource_path)

	for item_stack in inventory.potions:
		data["potions"].append({
			"potion_path": item_stack.item.resource_path,
			"count": item_stack.count
		})

	return data

static func _load_inventory(data: Dictionary) -> Inventory:
	var inv := Inventory.new()
	inv.gold = data.get("gold", 0)

	var equipped_path = data.get("equipped_weapon", "")
	if equipped_path != "":
		inv.equipped_weapon = load(equipped_path)

	for weapon_path in data.get("weapon_stash", []):
		var weapon = load(weapon_path)
		if weapon is Weapon:
			inv.weapon_stash.append(weapon)

	for item_data in data.get("potions", []):
		var item_path = item_data.get("potion_path", "")
		var count = item_data.get("count", 0)
		var item = load(item_path)
		if item is Potion:
			inv.potions.append(ItemStack.new(item, count))

	return inv

# ---------------------------------------------------------
# VILLAGE
# ---------------------------------------------------------
static func _get_village_data(village: Village) -> Dictionary:
	return {
		"name": village.name,
		"shop": _get_shop_data(village.shop),
		"inn": _get_inn_data(village.inn)
	}

static func _load_village(data: Dictionary) -> Village:
	var village := Village.new()
	village.name = data.get("name", "Unnamed Village")
	village.shop = _load_shop(data.get("shop", {}))
	village.inn = _load_inn(data.get("inn", {}))
	return village

# ---------------------------------------------------------
# SHOP
# ---------------------------------------------------------
static func _get_shop_data(shop: Shop) -> Dictionary:
	var data := {
		"name": shop.name,
		"inventory": []
	}

	for item_stack in shop.inventory:
		data["inventory"].append({
			"item_path": item_stack.item.resource_path,
			"count": item_stack.count
		})

	return data

static func _load_shop(data: Dictionary) -> Shop:
	var shop := Shop.new()
	shop.name = data.get("name", "Unnamed Shop")

	for item_data in data.get("inventory", []):
		var item_path = item_data.get("item_path", "")
		var count = item_data.get("count", 0)
		var item = load(item_path)
		if item is Item:
			shop.add_item(item, count)

	return shop

# ---------------------------------------------------------
# SHOP
# ---------------------------------------------------------
static func _get_inn_data(inn: Inn) -> Dictionary:
	return {
		"name": inn.name,
		"rest_cost": inn.rest_cost
	}

static func _load_inn(data: Dictionary) -> Inn:
	var inn := Inn.new()
	inn.name = data.get("name", "The Crooked Tusk")
	inn.rest_cost = data.get("rest_cost", 10)
	return inn
# ---------------------------------------------------------
# QUEST MANAGER
# ---------------------------------------------------------
static func _get_quests_data(quest_manager: QuestManager) -> Dictionary:
	var data := {
		"locked_quests": [],
		"available_quests": [],
		"completed_quests": []
	}
	for quest in quest_manager.locked_quests:
		data["locked_quests"].append(_get_quest_data(quest))
	for quest in quest_manager.available_quests:
		data["available_quests"].append(_get_quest_data(quest))
	for quest in quest_manager.completed_quests:
		data["completed_quests"].append(_get_quest_data(quest))
	return data

static func _load_quests(data: Dictionary) -> QuestManager:
	var manager := QuestManager.new()
	for quest_data in data.get("locked_quests", []):
		var quest = _load_quest(quest_data)
		manager.locked_quests.append(quest)
	for quest_data in data.get("available_quests", []):
		var quest = _load_quest(quest_data)
		manager.add_available_quest(quest)
	for quest_data in data.get("completed_quests", []):
		var quest = _load_quest(quest_data)
		manager.completed_quests.append(quest)
	return manager

# ---------------------------------------------------------
# QUESTS
# ---------------------------------------------------------
static func _get_quest_data(quest: Quest) -> Dictionary:
	var data := {
		"title": quest.title,
		"description": quest.description,
		"monster_objectives": [],
		"rewards": [],
		"completed": quest.completed,
	}
	# monster_objectives
	for obj in quest.monster_objectives:
		var obj_data = {
			"monster_path": obj.monster.resource_path,
			"target_amount": obj.target_amount,
			"current_amount": obj.current_amount
		}
		data["monster_objectives"].append(obj_data)
	# rewards
	for reward in quest.reward:
		var reward_data = {
			"reward_type": reward.reward_type,
		}
		match reward.reward_type:
			QuestReward.RewardType.ITEM:
				reward_data["item_path"] = reward.item.resource_path
				reward_data["amount"] = reward.amount
			QuestReward.RewardType.GOLD, QuestReward.RewardType.EXPERIENCE:
				reward_data["amount"] = reward.amount
			QuestReward.RewardType.CLASS_WEAPON:
				reward_data["weapon_rarity"] = reward.weapon_rarity
		data["rewards"].append(reward_data)
	return data

static func _load_quest(data: Dictionary) -> Quest:
	var quest := Quest.new()
	quest.title = data.get("title", "")
	quest.description = data.get("description", "")
	# monster_objectives
	for obj_data in data.get("monster_objectives", []):
		var obj = MonsterRequirement.new()
		obj.monster = load(obj_data.get("monster_path", ""))
		obj.target_amount = obj_data.get("target_amount", 1)
		obj.current_amount = obj_data.get("current_amount", 0)
		quest.monster_objectives.append(obj)
	# rewards
	for reward_data in data.get("rewards", []):
		var reward = QuestReward.new()
		reward.reward_type = reward_data.get("reward_type", QuestReward.RewardType.ITEM)
		match reward.reward_type:
			QuestReward.RewardType.ITEM:
				reward.item = load(reward_data.get("item_path", ""))
				reward.amount = reward_data.get("amount", 1)
			QuestReward.RewardType.GOLD, QuestReward.RewardType.EXPERIENCE:
				reward.amount = reward_data.get("amount", 1)
			QuestReward.RewardType.CLASS_WEAPON:
				reward.weapon_rarity = reward_data.get("weapon_rarity", Item.Rarity.COMMON)
		quest.reward.append(reward)
	quest.completed = data.get("completed", false)
	return quest
