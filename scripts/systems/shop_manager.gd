extends Node
class_name ShopManager

var hero: HeroInstance
var shop: Shop
var item_stack_selected: ItemStack

signal selected_changed()

func start_shop(hero_ref: HeroInstance, shop_ref: Shop) -> void:
	hero = hero_ref
	shop = shop_ref
	if not shop.inventory.is_empty():
		item_stack_selected = shop.inventory[0]
		emit_signal("selected_changed")

func can_buy_selected() -> bool:
	if hero.gold > item_stack_selected.item.value:
		return true
	return false

func buy_item(amount: int = 1) -> void:
	if can_buy_selected():
		item_stack_selected.count -= amount
		hero.gold -= item_stack_selected.item.value * amount
		if item_stack_selected.item is Potion:
			hero.add_potion(item_stack_selected.item)
		elif item_stack_selected.item is Weapon:
			hero.weapon = item_stack_selected.item
		if item_stack_selected.count < 1:
			var index = shop.inventory.find(item_stack_selected)
			shop.inventory.remove_at(index)
			if not shop.inventory.is_empty():
				item_stack_selected = shop.inventory[0]
				emit_signal("selected_changed")
