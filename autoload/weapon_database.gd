extends Node

var class_weapon_table := {
	Hero.HeroClass.ASSASSIN: {
		Item.Rarity.COMMON: [
			preload("res://resources/characters/weapons/assassin_weapons/common/curved_scimitar.tres"),
			preload("res://resources/characters/weapons/assassin_weapons/common/rusty_shortsword.tres"),
			preload("res://resources/characters/weapons/assassin_weapons/common/silent_dirk.tres"),
			preload("res://resources/characters/weapons/assassin_weapons/common/throwing_knives.tres"),
			preload("res://resources/characters/weapons/assassin_weapons/common/twin_daggers.tres"),
		],
		Item.Rarity.RARE: [
			preload("res://resources/characters/weapons/assassin_weapons/rare/eclipse_edge.tres"),
			preload("res://resources/characters/weapons/assassin_weapons/rare/shadowveil_katar.tres"),
			preload("res://resources/characters/weapons/assassin_weapons/rare/venomfang_blades.tres"),
		],
		Item.Rarity.LEGENDARY: [
			preload("res://resources/characters/weapons/assassin_weapons/legendary/shades_whisper.tres"),
			preload("res://resources/characters/weapons/assassin_weapons/legendary/widowmaker.tres"),
		],
	},
	Hero.HeroClass.KNIGHT: {
		Item.Rarity.COMMON: [
			preload("res://resources/characters/weapons/knight_weapons/common/bronze_mace.tres"),
			preload("res://resources/characters/weapons/knight_weapons/common/iron_longsword.tres"),
			preload("res://resources/characters/weapons/knight_weapons/common/soldiers_spear.tres"),
			preload("res://resources/characters/weapons/knight_weapons/common/steel_claymore.tres"),
			preload("res://resources/characters/weapons/knight_weapons/common/wooden_shieldblade.tres"),
		],
		Item.Rarity.RARE: [
			preload("res://resources/characters/weapons/knight_weapons/rare/knight_commanders_halberd.tres"),
			preload("res://resources/characters/weapons/knight_weapons/rare/oathkeeper_blade.tres"),
			preload("res://resources/characters/weapons/knight_weapons/rare/paladins_brand.tres"),
		],
		Item.Rarity.LEGENDARY: [
			preload("res://resources/characters/weapons/knight_weapons/legendary/aegisbreaker.tres"),
			preload("res://resources/characters/weapons/knight_weapons/legendary/valors_end.tres"),
		],
	},
	Hero.HeroClass.PRINCESS: {
		Item.Rarity.COMMON: [
			preload("res://resources/characters/weapons/princess_weapons/common/apprentices_wand.tres"),
			preload("res://resources/characters/weapons/princess_weapons/common/enchanted_fan.tres"),
			preload("res://resources/characters/weapons/princess_weapons/common/focus_orb.tres"),
			preload("res://resources/characters/weapons/princess_weapons/common/runed_staff.tres"),
			preload("res://resources/characters/weapons/princess_weapons/common/silver_scepter.tres"),
		],
		Item.Rarity.RARE: [
			preload("res://resources/characters/weapons/princess_weapons/rare/moonlight_wand.tres"),
			preload("res://resources/characters/weapons/princess_weapons/rare/royal_channelers_staff.tres"),
			preload("res://resources/characters/weapons/princess_weapons/rare/sages_mirror_orb.tres"),
		],
		Item.Rarity.LEGENDARY: [
			preload("res://resources/characters/weapons/princess_weapons/legendary/celestias_crownstaff.tres"),
			preload("res://resources/characters/weapons/princess_weapons/legendary/heart_of_eternity.tres"),
		],
	},
}

func get_random_weapon_for_class(hero_class: Hero.HeroClass, rarity: Item.Rarity):
	var class_list = class_weapon_table.get(hero_class, {})
	var weapon_list = class_list.get(rarity, [])
	if weapon_list.is_empty():
		push_warning("Weapon table empty for class")
		return null
	return weapon_list[randi() % weapon_list.size()]
