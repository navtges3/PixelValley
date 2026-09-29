extends Resource
class_name Reward

enum RecruitLevelMode { FIXED, PARTY_AVERAGE }

@export var experience := 0
@export var gold := 0
@export var items: Array[String] = []

@export_group("Random Weapon")
@export var random_weapon: bool = false
@export var rarity: Item.Rarity

@export_group("Loot")
@export var drop_chance: float = 1.0
@export var drop_table: DropTable = null

@export_group("Recruit")
@export var recruit_hero: bool = false
@export var recruit_hero_class: Hero.HeroClass = Hero.HeroClass.ASSASSIN
@export var recruit_level_mode: RecruitLevelMode = RecruitLevelMode.FIXED
@export_range(1, 99) var recruit_level: int = 1 # used when FIXED

func get_description() -> String:
	var description := "Reward:\n  XP: %d\n  Gold: %d" % [experience, gold]
	for item_id in items:
		var item := ItemLoader.get_item(item_id)
		description += "\n  %s" % (item.name if item else item_id)
	if random_weapon:
		description += "\n  Random %s weapon" % Item.rarity_to_string(rarity)
	if recruit_hero:
		description += "\n  Recruit hero"
	return description
