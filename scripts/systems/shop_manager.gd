extends Node
class_name ShopManager

var hero: Hero
var shop: Shop
var selected_item_id: String = ""

signal hero_updated(hero_ref: Hero)

func start_shop(hero_ref: Hero, shop_ref: Shop) -> void:
	hero = hero_ref
	shop = shop_ref
	if not shop.inventory.is_empty():
		selected_item_id = shop.inventory.keys()[0]
	emit_signal("hero_updated", hero)

func can_buy_selected(amount: int = 1) -> bool:
	var item := ItemLoader.get_item(selected_item_id)
	if item == null:
		return false
	return hero.inventory.gold >= item.value * amount

func buy_item(amount: int = 1) -> void:
	if not can_buy_selected(amount):
		return
	var item := ItemLoader.get_item(selected_item_id)
	hero.inventory.gold -= item.value * amount
	if item is Potion:
		hero.inventory.add_potion(selected_item_id, amount)
	if item is Weapon:
		hero.inventory.add_weapon_to_stash(selected_item_id)
	shop.remove_item(selected_item_id, amount)
	emit_signal("hero_updated", hero)
