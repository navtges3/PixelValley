extends Node

const SAVE_DIR := "user://saves"

var save_slot: int = 1

# ---------------------------------------------------------
# PATH HELPERS
# ---------------------------------------------------------
func get_slot_dir(slot: int = 1) -> String:
	var saves_dir := ProjectSettings.globalize_path(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(saves_dir)
	return saves_dir.path_join("slot_%d" % slot)

func _file(slot: int, filename: String) -> String:
	return get_slot_dir(slot).path_join(filename)

# ---------------------------------------------------------
# BASIC API
# ---------------------------------------------------------
func has_save_data(slot: int = 1) -> bool:
	var dir := get_slot_dir(slot)
	return FileAccess.file_exists(dir.path_join("meta.json"))

func new_save(slot: int = 1) -> void:
	save_slot = slot
	save_game()

func save_game() -> void:
	_save_json(save_slot, "hero.json", {
		"data": _get_hero_data(GameState.hero)
	})

	_save_json(save_slot, "village.json", {
		"data": _get_village_data(GameState.village)
	})

	_save_json(save_slot, "quests.json", {
		"data": _get_quests_data(GameState.quest_manager)
	})

	_save_json(save_slot, "world_state.json", {
		"data": WorldManager.get_save_data()
	})

	_save_json(save_slot, "meta.json", {
		"hero_name": GameState.hero.name,
		"level": GameState.hero.level,
		"time": Time.get_datetime_string_from_system(),
		"player_scene": GameState.player_location["scene"],
		"player_entrance": GameState.player_location["entrance_id"]
	})
	print("SaveManager: Saving player location: %s, %s" % [GameState.player_location["scene"], GameState.player_location["entrance_id"]])
	print("SaveManager: Saved game to slot %d" % save_slot)

func load_game(slot: int = 1) -> void:
	if not has_save_data(slot):
		push_error("SaveManager: no save data found for slot %d" % slot)
		return
	save_slot = slot

	var hero_json := _load_json(slot, "hero.json")
	GameState.hero = _load_hero(hero_json.get("data", {}))

	var village_json := _load_json(slot, "village.json")
	GameState.village = _load_village(village_json.get("data", {}))

	var quest_json := _load_json(slot, "quests.json")
	GameState.quest_manager = _load_quests(quest_json.get("data", {}))

	var world_json := _load_json(slot, "world_state.json")
	WorldManager.load_save_data(world_json.get("data", {}))

	var meta_json := _load_json(slot, "meta.json")
	var scene_int: int = meta_json.get("player_scene", ScreenManager.ScreenName.VALLEY)
	var entrance: String = meta_json.get("player_entrance", "")
	GameState.player_location = { "scene": scene_int, "entrance_id": entrance }
	GameState.quest_manager.reconnect_signals()
	print("SaveManager: Loading player location: %s, %s" % [GameState.player_location["scene"], GameState.player_location["entrance_id"]])
	print("SaveManager: Loaded game from slot %d" % slot)

func get_meta_data(slot: int = 1) -> Dictionary:
	var meta_json := _load_json(slot, "meta.json")
	return meta_json

func delete_slot(slot: int = 1) -> void:
	var dir := get_slot_dir(slot)
	if not DirAccess.dir_exists_absolute(dir):
		push_warning("SaveManager: No save data to delete for slot %d" % slot)
		return
	var files := ["hero.json", "village.json", "quests.json",
		"zone_state.json", "world_state.json", "meta.json"]
	for filename in files:
		var path := dir.path_join(filename)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(dir)
	print("SaveManager: Deleted slot %d" % slot)

# ---------------------------------------------------------
# LOW-LEVEL JSON HANDLING
# ---------------------------------------------------------
func _save_json(slot: int, filename: String, data: Dictionary) -> void:
	var dir:= get_slot_dir(slot)
	DirAccess.make_dir_recursive_absolute(dir)

	var file := FileAccess.open(dir.path_join(filename), FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to write %s" % filename)
		return

	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()

func _load_json(slot: int, filename: String) -> Dictionary:
	var path := _file(slot, filename)
	if not FileAccess.file_exists(path):
		push_error("SaveManager: Slot %d Missing file: %s" % [slot, filename])
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
func _get_hero_data(hero: Hero) -> Dictionary:
	return {
		"hero_name": hero.name,
		"portrait": hero.portrait.resource_path,
		"battle_visual": hero.battle_visual.resource_path,
		"world_visual": hero.world_visual.resource_path,
		"hero_class": hero.hero_class,
		"level": hero.level,
		"experience": hero.experience,
		"skill_points": hero.skill_points,

		"active_effects": _get_active_effects_data(hero),
		"stat_block": _get_stat_block_data(hero.stat_block),
		"inventory": _get_inventory_data(hero.inventory)
	}

func _load_hero(data: Dictionary) -> Hero:
	var hero := Hero.new()

	hero.name = data.get("hero_name", "Unnamed Hero")

	var portrait_path = data.get("portrait", "")
	if portrait_path != "":
		hero.portrait = load(portrait_path)

	var battle_visuals_path = data.get("battle_visual", "")
	if battle_visuals_path != "":
		hero.battle_visual = load(battle_visuals_path)

	var world_visuals_path = data.get("world_visual", "")
	if world_visuals_path != "":
		hero.world_visual = load(world_visuals_path)

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
func _get_active_effects_data(combatant: Combatant) -> Array:
	var result := []
	for ae in combatant.active_effects:
		result.append({
			"type": ae.effect.type,
			"strength": ae.effect.strength,
			"duration": ae.effect.duration,
			"remaining_turns": ae.remaining_turns
		})
	return result

func _load_active_effects(data: Array, combatant: Combatant) -> void:
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
func _get_stat_block_data(stat_block: StatBlock) -> Dictionary:
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

func _load_stat_block(data: Dictionary) -> StatBlock:
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
func _get_inventory_data(inventory: Inventory) -> Dictionary:
	return {
		"gold": inventory.gold,
		"equipped_weapon": ItemLoader.get_item_id(inventory.equipped_weapon),
		"weapon_stash": inventory.weapon_stash.duplicate(),
		"potions": inventory.potions.duplicate()
	}

func _load_inventory(data: Dictionary) -> Inventory:
	var inv := Inventory.new()
	inv.gold = data.get("gold", 0)

	var weapon_id = data.get("equipped_weapon", "")
	if weapon_id != "":
		var weapon = ItemLoader.get_item(weapon_id)
		if weapon is Weapon:
			inv.equipped_weapon = weapon

	for wid in data.get("weapon_stash", []):
		var resolved := _resolve_item_id(wid)
		if resolved != "" and ItemLoader.has_item(resolved):
			inv.weapon_stash.append(resolved)
		else:
			push_warning("SaveManager: unknown stash weapon '%s', skipping" % wid)

	for item_id in data.get("potions", {}):
		var resolved := _resolve_item_id(item_id)
		if resolved != "" and ItemLoader.has_item(resolved):
			inv.potions[resolved] = data["potions"][item_id]
		else:
			push_warning("SaveManager: unknown potion '%s', skipping" % item_id)

	return inv

# Consolidates the old migration path used in multiple places
func _resolve_item_id(id: String) -> String:
	if id.begins_with("res://"):
		return id.get_file().get_basename()
	return id

# ---------------------------------------------------------
# VILLAGE
# ---------------------------------------------------------
func _get_village_data(village: Village) -> Dictionary:
	return {
		"name": village.name,
		"shop": _get_shop_data(village.shop),
		"inn": _get_inn_data(village.inn)
	}

func _load_village(data: Dictionary) -> Village:
	var village := Village.new()
	village.name = data.get("name", "Unnamed Village")
	village.shop = _load_shop(data.get("shop", {}))
	village.inn = _load_inn(data.get("inn", {}))
	return village

# ---------------------------------------------------------
# SHOP
# ---------------------------------------------------------
func _get_shop_data(shop: Shop) -> Dictionary:
	return {
		"name": shop.name,
		"inventory": shop.inventory.duplicate()
	}

func _load_shop(data: Dictionary) -> Shop:
	var shop := Shop.new()
	shop.name = data.get("name", "Unnamed Shop")

	var inv: Dictionary = data.get("inventory", {})
	for item_id in inv:
		var resolved_id = item_id
		if (item_id as String).begins_with("res://"):
			resolved_id = (item_id as String).get_file().get_basename()
		if ItemLoader.has_item(resolved_id):
			shop.inventory[resolved_id] = inv[item_id]
		else:
			push_warning("SaveManager: unknown shop item '%s', skipping" % item_id)
	return shop

# ---------------------------------------------------------
# INN
# ---------------------------------------------------------
func _get_inn_data(inn: Inn) -> Dictionary:
	return {
		"name": inn.name,
		"rest_cost": inn.rest_cost
	}

func _load_inn(data: Dictionary) -> Inn:
	var inn := Inn.new()
	inn.name = data.get("name", "The Crooked Tusk")
	inn.rest_cost = data.get("rest_cost", 10)
	return inn

# ---------------------------------------------------------
# QUEST MANAGER
# ---------------------------------------------------------
func _get_quests_data(quest_manager: QuestManager) -> Dictionary:
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

func _load_quests(data: Dictionary) -> QuestManager:
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
func _get_quest_data(quest: Quest) -> Dictionary:
	var data := {
		"id": quest.id,
		"title": quest.title,
		"description": quest.description,
		"next_quests": quest.next_quests.duplicate(),
		"completed": quest.completed,
		"unlocks_locations": quest.unlocks_locations.duplicate(),
		"objectives": [],
		"rewards": [],
	}
	# objectives
	for obj in quest.objectives:
		data["objectives"].append({
			"monster_id": obj.monster_id,
			"target_amount": obj.target_amount,
			"current_amount": obj.current_amount,
			"location_id": obj.location_id
		})
	# reward
	data["reward"] = {
		"experience": quest.reward.experience,
		"gold": quest.reward.gold,
		"items": quest.reward.items.duplicate(),
		"random_weapon": quest.reward.random_weapon,
		"rarity": quest.reward.rarity
	}
	return data

func _load_quest(data: Dictionary) -> Quest:
	var quest := Quest.new()
	quest.id = data.get("id", 0)
	quest.title = data.get("title", "")
	quest.description = data.get("description", "")
	quest.completed = data.get("completed", false)
	# Restore next_quests so unlocking the follow-up works after a load.
	var raw_next: Array = data.get("next_quests", [])
	quest.next_quests.assign(raw_next)
	var raw_unlocks: Array = data.get("unlocks_locations", [])
	quest.unlocks_locations.assign(raw_unlocks)
	# objectives
	for obj_data in data.get("objectives", []):
		var obj := QuestObjective.new()
		obj.monster_id = obj_data.get("monster_id", MonsterLoader.MonsterID.GOBLIN)
		obj.target_amount = obj_data.get("target_amount", 1)
		obj.current_amount = obj_data.get("current_amount", 0)
		obj.location_id = obj_data.get("location_id", "")
		quest.objectives.append(obj)
	# reward
	var reward_data = data.get("reward", {})
	var reward := Reward.new()
	reward.experience = reward_data.get("experience", 0)
	reward.gold = reward_data.get("gold", 0)
	var items: Array = reward_data.get("items", [])
	reward.items.assign(items)
	reward.random_weapon = reward_data.get("random_weapon", false)
	reward.rarity = reward_data.get("rarity", Item.Rarity.COMMON)
	quest.reward = reward
	return quest
