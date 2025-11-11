extends Node
class_name SaveManager

const SAVE_DIR := "user://saves"
const MAX_SLOTS := 3

static func get_save_path(slot: int = 1) -> String:
	var saves_dir = ProjectSettings.globalize_path(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(saves_dir)
	return saves_dir.path_join("save_slot_%d.save" % slot)

static func has_save_data(slot: int = 1) -> bool:
	var save_path = get_save_path(slot)
	return FileAccess.file_exists(save_path)

static func save_game() -> void:
	var data = {
		hero = _get_hero_data(GameState.hero),
		village = _get_village_data(GameState.village),
		quests = GameState.quest_manager.get_save_data()
	}
	var save_path = get_save_path()
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	print("SaveManager: Game saved to slot ")

static func load_game() -> void:
	var save_path = get_save_path()
	if not FileAccess.file_exists(save_path):
		push_error("SaveManager: Save file not found at slot")
		return
	var file = FileAccess.open(save_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var data = JSON.parse_string(content)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("SaveManager: Invalid save data format in slot")
		return
	GameState.hero = _load_hero_data(data.get("hero", {}))
	GameState.village = _load_village(data.get("village", {}))
	GameState.quest_manager = QuestManager.load_from_data(data.get("quests", {}))
	return

static func _get_hero_data(hero: Hero) -> Dictionary:
	var hero_data = {
		hero_name = hero.name,
		portrait = hero.portrait.resource_path,
		hero_class = hero.hero_class,
		level = hero.level,
		experience = hero.experience,
		skill_points = hero.skill_points,
		active_effects = _get_active_effects_data(hero),
		stat_block = _get_stat_block_data(hero.stat_block),
		inventory = _get_inventory_data(hero.inventory)
	}
	return hero_data

static func _load_hero_data(data: Dictionary) -> Hero:
	var hero = Hero.new()
	hero.name = data.get("hero_name", "Unnamed Hero")
	var portrait_path = data.get("portrait", "")
	if portrait_path != "":
		hero.portrait = load(portrait_path)
	hero.hero_class = data.get("hero_class", "Warrior")
	hero.level = data.get("level", 1)
	hero.experience = data.get("experience", 0)
	hero.skill_points = data.get("skill_points", 0)
	hero.stat_block = _load_stat_block(data.get("stat_block", {}))
	hero.active_effects = _load_active_effects(data.get("active_effects", []))
	hero.inventory = _load_inventory(data.get("inventory", {}))
	return hero

static func _get_active_effects_data(combatant: Combatant) -> Array:
	var effects_data = []
	for effect in combatant.active_effects:
		effects_data.append({
			type = effect.type,
			strength = effect.strength,
			duration = effect.duration
		})
	return effects_data

static func _load_active_effects(data: Array) -> Array[Effect]:
	var effects: Array[Effect] = []
	for effect_data in data:
		var effect = Effect.new()
		effect.type = effect_data.get("type", Effect.EffectType.HEAL)
		effect.strength = effect_data.get("strength", 0)
		effect.duration = effect_data.get("duration", 0)
		effects.append(effect)
	return effects

static func _get_stat_block_data(stat_block: StatBlock) -> Dictionary:
	var stat_block_data = {
		current_hp = stat_block.current_hp,
		current_nrg = stat_block.current_nrg,
		max_hp = stat_block.max_hp,
		max_nrg = stat_block.max_nrg,
		attack = stat_block.attack,
		magic = stat_block.magic,
		defense = stat_block.defense,
		resistance = stat_block.resistance
	}
	return stat_block_data

static func _load_stat_block(data: Dictionary) -> StatBlock:
	var stat_block = StatBlock.new()
	stat_block.current_hp = data.get("current_hp", 10)
	stat_block.current_nrg = data.get("current_nrg", 5)
	stat_block.max_hp = data.get("max_hp", 10)
	stat_block.max_nrg = data.get("max_nrg", 5)
	stat_block.attack = data.get("attack", 1)
	stat_block.magic = data.get("magic", 1)
	stat_block.defense = data.get("defense", 1)
	stat_block.resistance = data.get("resistance", 1)
	return stat_block

static func _get_inventory_data(inventory: Inventory) -> Dictionary:
	var inventory_data = {
		gold = inventory.gold,
		equipped_weapon = inventory.equipped_weapon.resource_path,
		weapon_stash = [],
		potions = []
	}
	for weapon in inventory.weapon_stash:
		inventory_data.weapon_stash.append(weapon.resource_path)
	for item_stack in inventory.potions:
		inventory_data.potions.append({
			potion = item_stack.item.resource_path,
			count = item_stack.count
		})
	return inventory_data

static func _load_inventory(data: Dictionary) -> Inventory:
	var inventory = Inventory.new()
	inventory.gold = data.get("gold", 0)
	var weapon_path = data.get("equipped_weapon", "")
	if weapon_path != "":
		inventory.equipped_weapon = load(weapon_path)
	for stash_weapon_path in data.get("weapon_stash", []):
		var stash_weapon = load(stash_weapon_path)
		if stash_weapon is Weapon:
			inventory.add_weapon_to_stash(stash_weapon)
	for potion_data in data.get("potions", []):
		var potion_path = potion_data.get("potion", "")
		var count = potion_data.get("count", 1)
		if potion_path != "":
			var potion_item = load(potion_path)
			if potion_item is Potion:
				inventory.add_potion(potion_item, count)
	return inventory

static func _get_village_data(village: Village) -> Dictionary:
	var village_data = {
		name = village.name,
		shop = _get_shop_data(village.shop)
	}
	return village_data

static func _load_village(data: Dictionary) -> Village:
	var village = Village.new()
	village.name = data.get("name", "Lexiton")
	var shop_data = data.get("shop", {})
	village.shop = _load_shop(shop_data)
	return village

static func _get_shop_data(shop: Shop) -> Dictionary:
	var shop_data = {
		name = shop.name,
		inventory = []
	}
	for item_stack in shop.inventory:
		shop_data.inventory.append({
			item = item_stack.item.resource_path,
			count = item_stack.count
		})
	return shop_data

static func _load_shop(data: Dictionary) -> Shop:
	var shop = Shop.new()
	shop.name = data.get("name", "Default Shop")
	for item_data in data.get("inventory", []):
		var item = load(item_data.get("item", ""))
		var count = item_data.get("count", 1)
		if item:
			var item_stack = ItemStack.new(item, count)
			shop.inventory.append(item_stack)
	return shop
