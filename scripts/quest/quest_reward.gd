extends Resource
class_name QuestReward

enum RewardType {
	ITEM,
	GOLD,
	EXPERIENCE,
	CLASS_WEAPON
}

@export var reward_type: RewardType = RewardType.ITEM
@export var item: Item
@export var amount: int = 1
@export var weapon_rarity: Item.Rarity = Item.Rarity.COMMON

func get_description() -> String:
	match reward_type:
		RewardType.ITEM:
			return "Reward: %dx %s" % [amount, item.name]
		RewardType.GOLD:
			return "Reward: %d Gold" % amount
		RewardType.EXPERIENCE:
			return "Reward: %d Experience" % amount
		RewardType.CLASS_WEAPON:
			return "Reward: Random Class Weapon"
	return "Reward: Unknown"
