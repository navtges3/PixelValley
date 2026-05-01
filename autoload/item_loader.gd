extends Node

var _paths: Dictionary = {}
var _cache: Dictionary = {}

func _ready() -> void:
	_register_potions()
	_register_weapons()

func _register_potions() -> void:
	_register("lesser_healing_potion", "res://resources/items/potions/lesser_healing_potion.tres")
	_register("greater_healing_potion", "res://resources/items/potions/greater_healing_potion.tres")
	_register("regeneration_potion", "res://resources/items/potions/regeneration_potion.tres")
	_register("attack_potion", "res://resources/items/potions/attack_potion.tres")
	_register("magic_potion", "res://resources/items/potions/magic_potion.tres")
	_register("defense_potion", "res://resources/items/potions/defense_potion.tres")
	_register("resistance_potion", "res://resources/items/potions/resistance_potion.tres")
	_register("energy_potion", "res://resources/items/potions/energy_potion.tres")
	_register("stonehide_tonic", "res://resources/items/potions/stonehide_tonic.tres")

func _register_weapons() -> void:
	# Assassin - Common
	_register("rusty_shortsword", "res://resources/items/weapons/assassin_weapons/common/rusty_shortsword.tres")
	_register("silent_dirk", "res://resources/items/weapons/assassin_weapons/common/silent_dirk.tres")
	_register("throwing_knives", "res://resources/items/weapons/assassin_weapons/common/throwing_knives.tres")
	_register("twin_daggers", "res://resources/items/weapons/assassin_weapons/common/twin_daggers.tres")
	_register("curved_scimitar", "res://resources/items/weapons/assassin_weapons/common/curved_scimitar.tres")
	# Assassin - Rare
	_register("eclipse_edge", "res://resources/items/weapons/assassin_weapons/rare/eclipse_edge.tres")
	_register("shadowveil_katar", "res://resources/items/weapons/assassin_weapons/rare/shadowveil_katar.tres")
	_register("venomfang_blades", "res://resources/items/weapons/assassin_weapons/rare/venomfang_blades.tres")
	# Assassin - Legendary
	_register("shades_whisper", "res://resources/items/weapons/assassin_weapons/legendary/shades_whisper.tres")
	_register("widowmaker", "res://resources/items/weapons/assassin_weapons/legendary/widowmaker.tres")
	# Knight - Common
	_register("bronze_mace", "res://resources/items/weapons/knight_weapons/common/bronze_mace.tres")
	_register("iron_longsword", "res://resources/items/weapons/knight_weapons/common/iron_longsword.tres")
	_register("soldiers_spear", "res://resources/items/weapons/knight_weapons/common/soldiers_spear.tres")
	_register("steel_claymore", "res://resources/items/weapons/knight_weapons/common/steel_claymore.tres")
	_register("wooden_shieldblade", "res://resources/items/weapons/knight_weapons/common/wooden_shieldblade.tres")
	# Knight - Rare
	_register("knight_commanders_halberd", "res://resources/items/weapons/knight_weapons/rare/knight_commanders_halberd.tres")
	_register("oathkeeper_blade", "res://resources/items/weapons/knight_weapons/rare/oathkeeper_blade.tres")
	_register("paladins_brand", "res://resources/items/weapons/knight_weapons/rare/paladins_brand.tres")
	# Knight - Legendary
	_register("aegisbreaker", "res://resources/items/weapons/knight_weapons/legendary/aegisbreaker.tres")
	_register("valors_end", "res://resources/items/weapons/knight_weapons/legendary/valors_end.tres")
	# Princess - Common
	_register("apprentices_wand", "res://resources/items/weapons/princess_weapons/common/apprentices_wand.tres")
	_register("enchanted_fan", "res://resources/items/weapons/princess_weapons/common/enchanted_fan.tres")
	_register("focus_orb", "res://resources/items/weapons/princess_weapons/common/focus_orb.tres")
	_register("runed_staff", "res://resources/items/weapons/princess_weapons/common/runed_staff.tres")
	_register("silver_scepter", "res://resources/items/weapons/princess_weapons/common/silver_scepter.tres")
	# Princess - Rare
	_register("moonlight_wand", "res://resources/items/weapons/princess_weapons/rare/moonlight_wand.tres")
	_register("royal_channelers_staff", "res://resources/items/weapons/princess_weapons/rare/royal_channelers_staff.tres")
	_register("sages_mirror_orb", "res://resources/items/weapons/princess_weapons/rare/sages_mirror_orb.tres")
	# Princess - Legendary
	_register("celestias_crownstaff", "res://resources/items/weapons/princess_weapons/legendary/celestias_crownstaff.tres")
	_register("heart_of_eternity", "res://resources/items/weapons/princess_weapons/legendary/heart_of_eternity.tres")

func _register(id: String, path: String) -> void:
	if _paths.has(id):
		push_warning("ItemLoader: duplicate registration for '%s'" % id)
		return
	_paths[id] = path

func get_item(id: String) -> Item:
	if id == "":
		return null
	if _cache.has(id):
		return _cache[id]
	if _paths.has(id):
		var item := load(_paths[id]) as Item
		_cache[id] = item
		return item
	return null

func get_item_id(item: Item) -> String:
	if item == null:
		return ""
	for id in _cache:
		if _cache[id] == item:
			return id
	for id in _paths:
		var cached := get_item(id)
		if cached and cached.name == item.name:
			return id
	push_error("ItemLoader: item '%s' not registered" % item.name)
	return ""

func has_item(id: String) -> bool:
	return _paths.has(id)

func clear_cache() -> void:
	_cache.clear()
