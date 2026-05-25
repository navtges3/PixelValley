extends Control
class_name ShopScreen

enum ShopType { POTION, WEAPON }

const ENTRANCE_ID := "shop"

@export var shop_type: ShopType = ShopType.POTION

@onready var shop_manager = $ShopManager
@onready var item_list: VBoxContainer = $HBoxContainer/ListPanelContainer/ScrollContainer/ItemList
@onready var shop_name_label: Label = $ShopNameLabel
# Detail Panel
@onready var item_name_label: Label = $HBoxContainer/InfoPanelContainer/VBoxContainer/ItemNameLabel
@onready var item_description_label: Label = $HBoxContainer/InfoPanelContainer/VBoxContainer/ItemDescriptionLabel
@onready var item_cost_label: Label = $HBoxContainer/InfoPanelContainer/VBoxContainer/HBoxContainer/ItemCostLabel
@onready var quantity_spin_box: SpinBox = $HBoxContainer/InfoPanelContainer/VBoxContainer/HBoxContainer/SpinBox
@onready var ability_container: VBoxContainer = $HBoxContainer/InfoPanelContainer/VBoxContainer/ability_container
@onready var purchase_button: Button = $HBoxContainer/InfoPanelContainer/VBoxContainer/PurchaseButton
# Hero Panel
@onready var hero_ui: HeroInfo = $HBoxContainer/HeroPanelContainer/VBoxContainer/HeroUI
@onready var inventory_label: Label = $HBoxContainer/HeroPanelContainer/VBoxContainer/InventoryLabel

var ItemButton := preload("res://scenes/ui/components/item_button.tscn")

var hero: Hero
var shop: Shop

func _ready() -> void:
	hero = GameState.hero
	shop = _get_shop()
	shop_name_label.text = shop.name
	shop_manager.start_shop(hero, shop)
	quantity_spin_box.visible = shop_type == ShopType.POTION
	ability_container.visible = shop_type == ShopType.WEAPON
	_update_item_list()

func _get_shop() -> Shop:
	match shop_type:
		ShopType.WEAPON:
			return GameState.village.weapons_shop
		_:
			return GameState.village.shop

# ─── List ────────────────────────────────────────────────────────────────────

func empty_item_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

func create_item_button(item_id: String, count: int) -> Button:
	var button := ItemButton.instantiate()
	button.item_id = item_id
	button.count = count
	button.connect("item_pressed", Callable(self, "_on_item_pressed"))
	return button

func _update_item_list() -> void:
	empty_item_list()
	for item_id in shop.inventory:
		var count: int = shop.inventory[item_id]
		var button = create_item_button(item_id, count)
		item_list.add_child(button)
	if shop_manager.selected_item_id != "":
		_on_item_pressed(shop_manager.selected_item_id)

# ─── Detail Panel ─────────────────────────────────────────────────────────────

func _on_item_pressed(item_id: String) -> void:
	shop_manager.selected_item_id = item_id
	_refresh_detail_panel(item_id)

func _refresh_detail_panel(item_id: String) -> void:
	var item := ItemLoader.get_item(item_id)
	if item == null:
		return
	item_name_label.text = item.name
	item_description_label.text = item.description
	if shop_type == ShopType.POTION:
		quantity_spin_box.value = 1
		quantity_spin_box.max_value = shop.inventory.get(item_id, 1)
	elif shop_type == ShopType.WEAPON:
		_refresh_ability_list(item as Weapon)
	_update_item_cost()
	_update_purchase_button()

func _refresh_ability_list(weapon: Weapon) -> void:
	for child in ability_container.get_children():
		child.queue_free()
	if weapon == null:
		return
	for ability in weapon.abilities:
		var label := Label.new()
		label.text = "- %s" % ability.name
		ability_container.add_child(label)

func _update_item_cost() -> void:
	var item := ItemLoader.get_item(shop_manager.selected_item_id)
	if item:
		var qty := int(quantity_spin_box.value) if ShopType.POTION else 1
		item_cost_label.text = str(item.value * qty)

func _update_purchase_button() -> void:
	var item := ItemLoader.get_item(shop_manager.selected_item_id)
	if item:
		var qty := int(quantity_spin_box.value) if ShopType.POTION else 1
		purchase_button.disabled = item.value * qty > hero.inventory.gold
	else:
		purchase_button.disabled = true

# ─── Hero Panel ───────────────────────────────────────────────────────────────

func _on_shop_manager_hero_updated(hero_ref: Hero) -> void:
	if hero_ui.hero:
		hero_ui.refresh()
	else:
		hero_ui.hero = hero_ref
	match shop_type:
		ShopType.POTION:
			_refresh_potion_inventory(hero_ref)
		ShopType.WEAPON:
			_refresh_weapon_inventory(hero_ref)

func _refresh_potion_inventory(hero_ref: Hero) -> void:
	var text := "Hero Inventory:"
	if hero_ref.inventory.potions.is_empty():
		text += "\n  None"
	else:
		for item_id in hero_ref.inventory.potions:
			var count: int = hero_ref.inventory.potions[item_id]
			var item := ItemLoader.get_item(item_id)
			text += "\n - %s x%d" % [item.name if item else item_id, count]
	inventory_label.text = text

func _refresh_weapon_inventory(hero_ref: Hero) -> void:
	var text := "Equipped: "
	var equipped := hero_ref.inventory.equipped_weapon
	text += equipped.name if equipped else "None"
	text += "\n\nOwned:"
	if hero_ref.inventory.weapon_stash.is_empty():
		text += "\n  None"
	else:
		for weapon_id in hero_ref.inventory.weapon_stash:
			var item := ItemLoader.get_item(weapon_id)
			text += "\n - %s" % (item.name if item else weapon_id)
	inventory_label.text = text

# ─── Actions ─────────────────────────────────────────────────────────────────

func _on_spin_box_value_changed(_value: float) -> void:
	_update_item_cost()
	_update_purchase_button()

func _on_purchase_button_pressed() -> void:
	if shop_manager.selected_item_id == "":
		return
	var qty := int(quantity_spin_box.value) if shop_type == ShopType.POTION else 1
	shop_manager.buy_item(qty)
	AudioManager.play_sfx_by_id("back_of_coins")
	_update_item_list()

func _on_exit_button_pressed() -> void:
	ScreenManager.go_back(ENTRANCE_ID)
