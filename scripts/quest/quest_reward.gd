extends Resource
class_name QuestReward

enum RewardTarget {
	PLAYER,
	SHOP,
	VILLAGE
}

@export var item: Item
@export var amount: int = 1
@export var target: RewardTarget = RewardTarget.PLAYER

func get_description() -> String:
	var target_str := ""
	match target:
		RewardTarget.PLAYER:
			target_str = "Player"
		RewardTarget.SHOP:
			target_str = "Shop"
		RewardTarget.VILLAGE:
			target_str = "Village"
	return "%s: %s x%d" % [target_str, item.name, amount]

func get_save_data() -> Dictionary:
	return {
		"item_path": item.resource_path,
		"amount": amount,
		"target": target
	}

static func load_from_data(data: Dictionary) -> QuestReward:
	var reward := QuestReward.new()
	reward.item = load(data.get("item_path", ""))
	reward.amount = data.get("amount", 1)
	reward.target = data.get("target", RewardTarget.PLAYER)
	return reward
