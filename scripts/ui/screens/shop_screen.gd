extends Control

const LOCATION_ID := "shop"

@onready var shop_manager = $ShopManager
@onready var item_list: VBoxContainer = $HBoxContainer/ListPanelContainer/ScrollContainer/ItemList
@onready var shop_name_label: Label = $ShopNameLabel
# Detail Panel
@onready var item_name_label: Label = $HBoxContainer/InfoPanelContainer/VBoxContainer/ItemNameLabel
@onready var item_description_label: Label = $HBoxContainer/InfoPanelContainer/VBoxContainer/ItemDescriptionLabel
@onready var item_cost_label: Label = $HBoxContainer/InfoPanelContainer/VBoxContainer/HBoxContainer/ItemCostLabel
@onready var quantity_spin_box: SpinBox = $HBoxContainer/InfoPanelContainer/VBoxContainer/HBoxContainer/SpinBox

@onready var purchase_button: Button = $HBoxContainer/InfoPanelContainer/VBoxContainer/PurchaseButton

@onready var hero_ui: HeroInfo = $HBoxContainer/HeroPanelContainer/VBoxContainer/HeroUI
@onready var inventory_label: Label = $HBoxContainer/HeroPanelContainer/VBoxContainer/InventoryLabel

var ItemButton := preload("res://scenes/ui/components/item_button.tscn")

var hero: Hero
var shop: Shop

func _ready() -> void:
	hero = GameState.hero
	shop = GameState.village.shop
	shop_name_label.text = shop.name
	shop_manager.start_shop(hero, shop)
	_update_item_list()

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

func _on_item_pressed(item_id: String) -> void:
	shop_manager.selected_item_id = item_id
	_refresh_detail_panel(item_id)

func _refresh_detail_panel(item_id: String) -> void:
	var item := ItemLoader.get_item(item_id)
	if item == null:
		return
	item_name_label.text = item.name
	item_description_label.text = item.description
	quantity_spin_box.value = 1
	quantity_spin_box.max_value = shop.inventory.get(item_id, 1)
	_update_item_cost()
	_update_purchase_button()

func _update_item_cost() -> void:
	var item := ItemLoader.get_item(shop_manager.selected_item_id)
	if item:
		item_cost_label.text = str(item.value * int(quantity_spin_box.value))

func _update_purchase_button() -> void:
	var item := ItemLoader.get_item(shop_manager.selected_item_id)
	if item:
		purchase_button.disabled = item.value * int(quantity_spin_box.value) > hero.inventory.gold
	else:
		purchase_button.disabled = true

func _on_shop_manager_hero_updated(hero_ref: Hero) -> void:
	if hero_ui.hero:
		hero_ui.refresh()
	else:
		hero_ui.hero = hero_ref
	var inventory_text := "Hero Inventory:"
	if hero_ref.inventory.potions.is_empty():
		inventory_text += "\n  None"
	else:
		for item_id in hero_ref.inventory.potions:
			var count: int = hero_ref.inventory.potions[item_id]
			var item := ItemLoader.get_item(item_id)
			inventory_text += "\n - %s x%d" % [item.name if item else item_id, count]
	inventory_label.text = inventory_text
	
func _on_spin_box_value_changed(_value: float) -> void:
	_update_item_cost()
	_update_purchase_button()

func _on_purchase_button_pressed() -> void:
	if shop_manager.selected_item_id == "":
		return
	shop_manager.buy_item(int(quantity_spin_box.value))
	_update_item_list()

func _on_exit_button_pressed() -> void:
	ScreenManager.go_back(LOCATION_ID)
