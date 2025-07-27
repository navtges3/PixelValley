extends Node
class_name ShopManager

var hero: HeroInstance
var shop: Shop
var item_stack_selected: ItemStack

signal hero_updated(hero_ref: HeroInstance)

func start_shop(hero_ref: HeroInstance, shop_ref: Shop) -> void:
	hero = hero_ref
	shop = shop_ref
	if not shop.inventory.is_empty():
		item_stack_selected = shop.inventory[0]
	emit_signal("hero_updated", hero)

func can_buy_selected(amount: int = 1) -> bool:
	if hero.gold >= item_stack_selected.item.value * amount:
		return true
	return false

func buy_item(amount: int = 1) -> void:
	if can_buy_selected(amount):
		print("Buying item: ", item_stack_selected.item.name, " x", amount)
		item_stack_selected.count -= amount
		hero.gold -= item_stack_selected.item.value * amount
		if item_stack_selected.item is Potion:
			if "add_potion" in hero and hero.add_potion.get_argument_count() == 2:
				hero.add_potion(item_stack_selected.item, amount)
			else:
				for i in range(amount):
					hero.add_potion(item_stack_selected.item)
		elif item_stack_selected.item is Weapon:
			hero.weapon = item_stack_selected.item
		if item_stack_selected.count < 1:
			var index = shop.inventory.find(item_stack_selected)
			shop.inventory.remove_at(index)
			if not shop.inventory.is_empty():
				item_stack_selected = shop.inventory[0]
		emit_signal("hero_updated", hero)
