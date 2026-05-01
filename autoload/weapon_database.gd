extends Node

const CLASS_WEAPON_TABLE := {
	Hero.HeroClass.ASSASSIN: {
		Item.Rarity.COMMON:     ["rusty_shortsword", "silent_dirk", "throwing_knives", "twin_daggers", "curved_scimitar"],
		Item.Rarity.RARE:       ["eclipse_edge", "shadowveil_katar", "venomfang_blades"],
		Item.Rarity.LEGENDARY:  ["shades_whisper", "widowmaker"],
	},
	Hero.HeroClass.KNIGHT: {
		Item.Rarity.COMMON:     ["bronze_mace", "iron_longsword", "soldiers_spear", "steel_claymore", "wooden_shieldblade"],
		Item.Rarity.RARE:       ["knight_commanders_halberd", "oathkeeper_blade", "paladins_brand"],
		Item.Rarity.LEGENDARY:  ["aegisbreaker", "valors_end"],
	},
	Hero.HeroClass.PRINCESS: {
		Item.Rarity.COMMON:     ["apprentices_wand", "enchanted_fan", "focus_orb", "runed_staff", "silver_scepter"],
		Item.Rarity.RARE:       ["moonlight_wand", "royal_channelers_staff", "sages_mirror_orb"],
		Item.Rarity.LEGENDARY:  ["celestias_crownstaff", "heart_of_eternity"],
	},
}

const GOLD_BY_RARITY := {
	Item.Rarity.COMMON:     50,
	Item.Rarity.RARE:      150,
	Item.Rarity.LEGENDARY: 400,
}

func get_random_unowned_weapon_id_for_class(hero_class: Hero.HeroClass, rarity: Item.Rarity) -> String:
	var class_list: Dictionary = CLASS_WEAPON_TABLE.get(hero_class, {})
	var all_ids: Array = class_list.get(rarity, [])
	var unowned_ids := all_ids.filter(
		func(id: String) -> bool:
			return not GameState.hero.inventory.has_weapon_in_stash(id)
	)
	if unowned_ids.is_empty():
		return ""
	return unowned_ids[randi() % unowned_ids.size()]

func get_gold_fallback_for_rarity(rarity: Item.Rarity) -> int:
	return GOLD_BY_RARITY.get(rarity, 50)
