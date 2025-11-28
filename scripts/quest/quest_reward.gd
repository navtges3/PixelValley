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


func get_save_data() -> Dictionary:
	var data = {
		"reward_type": reward_type,
	}
	match reward_type:
		RewardType.ITEM:
			data["item_path"] = item.resource_path
			data["amount"] = amount
		RewardType.GOLD, RewardType.EXPERIENCE:
			data["amount"] = amount
		RewardType.CLASS_WEAPON:
			data["weapon_rarity"] = weapon_rarity
	return data


static func load_from_data(data: Dictionary) -> QuestReward:
	var reward := QuestReward.new()
	reward.reward_type = data.get("reward_type", RewardType.ITEM)

	match reward.reward_type:
		RewardType.ITEM:
			reward.item = load(data.get("item_path", ""))
			reward.amount = data.get("amount", 1)
		RewardType.GOLD, RewardType.EXPERIENCE:
			reward.amount = data.get("amount", 1)
		RewardType.CLASS_WEAPON:
			reward.weapon_rarity = data.get("weapon_rarity", Item.Rarity.COMMON)
	return reward
