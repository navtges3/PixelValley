extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var reward_label: Label = $VBoxContainer/RewardLabel
@onready var collect_reward_button: Button = $VBoxContainer/CollectRewardButton

const GOLD_ITEM = preload("res://resources/items/gold.tres")
const EXPERIENCE_ITEM = preload("res://resources/items/experience.tres")

func _ready() -> void:
	var current_quest = GameState.current_quest
	title_label.text = current_quest.title

	status_label.text = "Completed"
	var reward_text = ""
	for reward in current_quest.reward:
		reward_text += reward.get_description() + "\n"
	reward_label.text = reward_text.strip_edges()

func _on_collect_reward_button_pressed() -> void:
	collect_rewards()
	ScreenManager.go_to_screen("village")

func collect_rewards() -> void:
	var hero = GameState.hero
	var village = GameState.village
	for reward:QuestReward in GameState.current_quest.reward:
		match reward.target:
			QuestReward.RewardTarget.PLAYER:
				if reward.item is Potion:
					print("Adding %d %s to hero's inventory" % [reward.amount, reward.item.name])
					hero.inventory.add_potion(reward.item, reward.amount)
				elif reward.item is Weapon:
					print("Adding %d %s to hero's weapon stash" % [reward.amount, reward.item.name])
					hero.inventory.add_weapon_to_stash(reward.item)
				elif reward.item == GOLD_ITEM:
					print("Adding %d gold to hero's inventory" % reward.amount)
					hero.inventory.gold += reward.amount
				elif reward.item == EXPERIENCE_ITEM:
					print("Adding %d experience to hero" % reward.amount)
					hero.gain_experience(reward.amount)
				else:
					print("Unknown item type")
			QuestReward.RewardTarget.SHOP:
				print("Adding %d %s to shop's inventory" % [reward.amount, reward.item.name])
				village.shop.add_item(reward.item, reward.amount)
