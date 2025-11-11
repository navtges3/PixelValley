extends Node
class_name ShopManager

var hero: Hero
var shop: Shop
var item_stack_selected: ItemStack

signal hero_updated(hero_ref: Hero)

func start_shop(hero_ref: Hero, shop_ref: Shop) -> void:
	hero = hero_ref
	shop = shop_ref
	if not shop.inventory.is_empty():
		item_stack_selected = shop.inventory[0]
	emit_signal("hero_updated", hero)

func can_buy_selected(amount: int = 1) -> bool:
	if hero.inventory.gold >= item_stack_selected.item.value * amount:
		return true
	return false

func buy_item(amount: int = 1) -> void:
	if can_buy_selected(amount):
		print("Buying item: ", item_stack_selected.item.name, " x", amount)
		hero.inventory.gold -= item_stack_selected.item.value * amount
		if item_stack_selected.item is Potion:
			hero.inventory.add_potion(item_stack_selected.item.duplicate(true), amount)
		elif item_stack_selected.item is Weapon:
			shop.add_item(hero.inventory.equipped_weapon)
			hero.inventory.equipped_weapon = item_stack_selected.item
		shop.remove_item(item_stack_selected.item, amount)
		emit_signal("hero_updated", hero)
