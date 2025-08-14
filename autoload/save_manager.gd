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
	GameState.village = _load_village_data(data.get("village", {}))
	return

static func _get_hero_data(hero: Hero) -> Dictionary:
	var hero_data = {
		hero_name = hero.name,
		portrait = hero.portrait.resource_path,
		current_hp = hero.current_hp,
		current_nrg = hero.current_nrg,
		active_effects = [],
		stat_block = {
			max_hp = hero.stat_block.max_hp,
			max_nrg = hero.stat_block.max_nrg,
			attack = hero.stat_block.attack,
			magic = hero.stat_block.magic,
			defense = hero.stat_block.defense,
			resistance = hero.stat_block.resistance
		},
		hero_class = hero.hero_class,
		level = hero.level,
		experience = hero.experience,
		inventory = {
			weapon = hero.inventory.weapon.resource_path,
			potions = []
		}
	}
	for effect in hero.active_effects:
		hero_data.active_effects.append({
			type = effect.type,
			strength = effect.strength,
			duration = effect.duration
		})
	for item_stack in hero.inventory.potions:
		hero_data.inventory.potions.append({
			potion = item_stack.item.resource_path,
			count = item_stack.count
		})
	return hero_data

static func _load_hero_data(data: Dictionary) -> Hero:
	var hero = Hero.new()
	hero.name = data.get("hero_name", "Unnamed Hero")
	var portrait_path = data.get("portrait", "")
	if portrait_path != "":
		hero.portrait = load(portrait_path)
	hero.current_hp = data.get("current_hp", 0)
	hero.current_nrg = data.get("current_nrg", 0)
	hero.stat_block = StatBlock.new()
	var stat_data = data.get("stat_block", {})
	hero.stat_block.max_hp = stat_data.get("max_hp", 10)
	hero.stat_block.max_nrg = stat_data.get("max_nrg", 5)
	hero.stat_block.attack = stat_data.get("attack", 1)
	hero.stat_block.magic = stat_data.get("magic", 1)
	hero.stat_block.defense = stat_data.get("defense", 1)
	hero.stat_block.resistance = stat_data.get("resistance", 1)
	hero.active_effects = []
	for effect_data in data.get("active_effects", []):
		var effect = Effect.new()
		effect.type = effect_data.get("type", Effect.EffectType.HEAL)
		effect.strength = effect_data.get("strength", 0)
		effect.duration = effect_data.get("duration", 0)
		hero.active_effects.append(effect)
	hero.hero_class = data.get("hero_class", "Warrior")
	hero.level = data.get("level", 1)
	hero.experience = data.get("experience", 0)
	hero.inventory = Inventory.new()
	var inventory_data = data.get("inventory", {})
	var weapon_path = inventory_data.get("weapon", "")
	if weapon_path != "":
		hero.inventory.weapon = load(weapon_path)
	hero.inventory.potions = []
	for potion_data in inventory_data.get("potions", []):
		var potion_path = potion_data.get("potion", "")
		var count = potion_data.get("count", 1)
		if potion_path != "":
			var potion_item = load(potion_path)
			if potion_item is Potion:
				var item_stack = ItemStack.new(potion_item, count)
				hero.inventory.potions.append(item_stack)
	return hero

static func _get_village_data(village: Village) -> Dictionary:
	var village_data = {
		name = village.name,
		shop = _get_shop_data(village.shop)
	}
	return village_data

static func _load_village_data(data: Dictionary) -> Village:
	var village = Village.new()
	village.name = data.get("name", "Lexiton")
	var shop_data = data.get("shop", {})
	village.shop = _load_shop_data(shop_data)
	return village

static func _get_shop_data(shop: Shop) -> Dictionary:
	var shop_data = {
		name = shop.name,
		inventory = []
	}
	for item_stack in shop.inventory:
		shop_data.inventory.append({
			item_stack = item_stack.item.resource_path,
			count = item_stack.count
		})
	return shop_data

static func _load_shop_data(data: Dictionary) -> Shop:
	var shop = Shop.new()
	shop.name = data.get("name", "Default Shop")
	shop.inventory = []
	for item_data in data.get("inventory", []):
		var item = load(item_data.get("item", ""))
		var count = item_data.get("count", 1)
		if item:
			var item_stack = ItemStack.new(item, count)
			shop.inventory.append(item_stack)
	return shop
