extends Node
class_name ShopManager

var hero: HeroInstance
var shop: Shop
var item_stack_selected: ItemStack

func start_shop(hero_ref: HeroInstance, shop_ref: Shop) -> void:
	hero = hero_ref
	shop = shop_ref
	item_stack_selected = shop.inventory[0]