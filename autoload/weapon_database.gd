extends Node

var class_weapon_table := {
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

func get_random_weapon_for_class(hero_class: Hero.HeroClass, rarity: Item.Rarity):
	var class_list = class_weapon_table.get(hero_class, {})
	var id_list = class_list.get(rarity, [])
	if id_list.is_empty():
		push_warning("WeaponDatabase: no weapons for class/rarity combo")
		return null
	var id: String = id_list[randi() % id_list.size()]
	return ItemLoader.get_item(id) as Weapon
