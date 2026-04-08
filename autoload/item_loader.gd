extends Node

var _registry: Dictionary = {}

func _ready() -> void:
	_register_potions()
	_register_weapons()

func _register_potions() -> void:
	_register("lesser_healing_potion", preload("res://resources/items/potions/lesser_healing_potion.tres"))
	_register("greater_healing_potion", preload("res://resources/items/potions/greater_healing_potion.tres"))
	_register("regeneration_potion", preload("res://resources/items/potions/regeneration_potion.tres"))
	_register("attack_potion", preload("res://resources/items/potions/attack_potion.tres"))
	_register("magic_potion", preload("res://resources/items/potions/magic_potion.tres"))
	_register("defense_potion", preload("res://resources/items/potions/defense_potion.tres"))
	_register("resistance_potion", preload("res://resources/items/potions/resistance_potion.tres"))
	_register("energy_potion", preload("res://resources/items/potions/energy_potion.tres"))
	_register("stonehide_tonic", preload("res://resources/items/potions/stonehide_tonic.tres"))

func _register_weapons() -> void:
	# Assassin - Common
	_register("rusty_shortsword", preload("res://resources/items/weapons/assassin_weapons/common/rusty_shortsword.tres"))
	_register("silent_dirk", preload("res://resources/items/weapons/assassin_weapons/common/silent_dirk.tres"))
	_register("throwing_knives", preload("res://resources/items/weapons/assassin_weapons/common/throwing_knives.tres"))
	_register("twin_daggers", preload("res://resources/items/weapons/assassin_weapons/common/twin_daggers.tres"))
	_register("curved_scimitar", preload("res://resources/items/weapons/assassin_weapons/common/curved_scimitar.tres"))
	# Assassin - Rare
	_register("eclipse_edge", preload("res://resources/items/weapons/assassin_weapons/rare/eclipse_edge.tres"))
	_register("shadowveil_katar", preload("res://resources/items/weapons/assassin_weapons/rare/shadowveil_katar.tres"))
	_register("venomfang_blades", preload("res://resources/items/weapons/assassin_weapons/rare/venomfang_blades.tres"))
	# Assassin - Legendary
	_register("shades_whisper", preload("res://resources/items/weapons/assassin_weapons/legendary/shades_whisper.tres"))
	_register("widowmaker", preload("res://resources/items/weapons/assassin_weapons/legendary/widowmaker.tres"))
	# Knight - Common
	_register("bronze_mace", preload("res://resources/items/weapons/knight_weapons/common/bronze_mace.tres"))
	_register("iron_longsword", preload("res://resources/items/weapons/knight_weapons/common/iron_longsword.tres"))
	_register("soldiers_spear", preload("res://resources/items/weapons/knight_weapons/common/soldiers_spear.tres"))
	_register("steel_claymore", preload("res://resources/items/weapons/knight_weapons/common/steel_claymore.tres"))
	_register("wooden_shieldblade", preload("res://resources/items/weapons/knight_weapons/common/wooden_shieldblade.tres"))
	# Knight - Rare
	_register("knight_commanders_halberd", preload("res://resources/items/weapons/knight_weapons/rare/knight_commanders_halberd.tres"))
	_register("oathkeeper_blade", preload("res://resources/items/weapons/knight_weapons/rare/oathkeeper_blade.tres"))
	_register("paladins_brand", preload("res://resources/items/weapons/knight_weapons/rare/paladins_brand.tres"))
	# Knight - Legendary
	_register("aegisbreaker", preload("res://resources/items/weapons/knight_weapons/legendary/aegisbreaker.tres"))
	_register("valors_end", preload("res://resources/items/weapons/knight_weapons/legendary/valors_end.tres"))
	# Princess - Common
	_register("apprentices_wand", preload("res://resources/items/weapons/princess_weapons/common/apprentices_wand.tres"))
	_register("enchanted_fan", preload("res://resources/items/weapons/princess_weapons/common/enchanted_fan.tres"))
	_register("focus_orb", preload("res://resources/items/weapons/princess_weapons/common/focus_orb.tres"))
	_register("runed_staff", preload("res://resources/items/weapons/princess_weapons/common/runed_staff.tres"))
	_register("silver_scepter", preload("res://resources/items/weapons/princess_weapons/common/silver_scepter.tres"))
	# Princess - Rare
	_register("moonlight_wand", preload("res://resources/items/weapons/princess_weapons/rare/moonlight_wand.tres"))
	_register("royal_channelers_staff", preload("res://resources/items/weapons/princess_weapons/rare/royal_channelers_staff.tres"))
	_register("sages_mirror_orb", preload("res://resources/items/weapons/princess_weapons/rare/sages_mirror_orb.tres"))
	# Princess - Legendary
	_register("celestias_crownstaff", preload("res://resources/items/weapons/princess_weapons/legendary/celestias_crownstaff.tres"))
	_register("heart_of_eternity", preload("res://resources/items/weapons/princess_weapons/legendary/heart_of_eternity.tres"))

func _register(id: String, item: Item) -> void:
	if _registry.has(id):
		push_warning("ItemLoader: duplicate registration for '%s'" % id)
		return
	_registry[id] = item

# --- Public API ---

func get_item(id: String) -> Item:
	if id == "":
		return null
	# Direct registry lookup (fast path)
	if _registry.has(id):
		return _registry[id]
	# Migration: id is actually a full resource path from an old save
	if id.begins_with("res://"):
		var filename := id.get_file().get_basename()
		if _registry.has(filename):
			return _registry[filename]
		push_warning("ItemLoader: path '%s' not in registry, falling back to load()" % id)
		return load(id)
	push_error("ItemLoader: unknown item id '%s'" % id)
	return null

func get_item_id(item: Item) -> String:
	if item == null:
		return ""
	# Fast path: exact reference match
	for id in _registry:
		if _registry[id] == item:
			return id
	# Fallback: name match for duplicated resources (e.g. shop items)
	for id in _registry:
		if _registry[id].name == item.name:
			return id
	push_error("ItemLoader: item '%s' has no registered id - was it registered?" % item.name)
	return ""

func has_item(id: String) -> bool:
	return _registry.has(id)
