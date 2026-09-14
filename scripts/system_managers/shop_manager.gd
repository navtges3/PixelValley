extends Node
class_name ShopManager

var hero: Hero
var party: Party
var shop: Shop
var selected_item_id: String = ""

signal hero_updated(hero_ref: Hero)

func start_shop(hero_ref: Hero, party_ref: Party, shop_ref: Shop) -> void:
	hero = hero_ref
	party = party_ref
	shop = shop_ref
	if not shop.inventory.is_empty():
		selected_item_id = shop.inventory.keys()[0]
	else:
		selected_item_id = ""
	emit_signal("hero_updated", hero)

func can_buy_selected(amount: int = 1) -> bool:
	if hero == null or party == null:
		return false
	if shop == null or not shop.inventory.has(selected_item_id):
		return false
	if shop.inventory[selected_item_id] < amount:
		return false
	var item := ItemLoader.get_item(selected_item_id)
	if item == null:
		return false
	if item is Weapon and party.has_weapon(selected_item_id):
		return false
	return party.inventory.gold >= item.value * amount

func buy_item(amount: int = 1) -> void:
	if not can_buy_selected(amount):
		return
	var item := ItemLoader.get_item(selected_item_id)
	party.inventory.gold -= item.value * amount
	if item is Potion:
		party.inventory.add_potion(selected_item_id, amount)
	if item is Weapon:
		party.inventory.add_weapon(selected_item_id)
	shop.remove_item(selected_item_id, amount)
	if not shop.inventory.has(selected_item_id):
		selected_item_id = shop.inventory.keys()[0] if not shop.inventory.is_empty() else ""
	emit_signal("hero_updated", hero)
