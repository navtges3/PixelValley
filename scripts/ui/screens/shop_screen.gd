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
var item_cost: int

func _ready() -> void:
	hero = GameState.hero
	shop = GameState.village.shop

	shop_name_label.text = shop.name
	shop_manager.start_shop(hero, shop)
	_update_item_list()

func empty_item_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

func create_item_button(item_stack: ItemStack) -> Button:
	var button := ItemButton.instantiate()
	button.item_stack = item_stack
	button.connect("item_pressed", Callable(self, "_on_item_pressed"))
	return button

func _update_item_list() -> void:
	empty_item_list()
	for item_stack in shop.inventory:
		var button = create_item_button(item_stack)
		item_list.add_child(button)
	if shop_manager.item_stack_selected:
		_on_item_pressed(shop_manager.item_stack_selected)

func _on_item_pressed(item_stack: ItemStack) -> void:
	item_name_label.text = item_stack.item.name
	item_description_label.text = item_stack.item.description
	item_cost_label.text = str(item_stack.item.value)
	shop_manager.item_stack_selected = item_stack

	quantity_spin_box.value = 1
	quantity_spin_box.max_value = item_stack.count if item_stack and item_stack.item else 1

	_update_item_cost()
	_update_purchase_button()

func _update_item_cost() -> void:
	item_cost_label.text = str(shop_manager.item_stack_selected.item.value * quantity_spin_box.value)

func _update_purchase_button() -> void:
	var selected_stack = shop_manager.item_stack_selected
	if selected_stack and selected_stack.item:
		var total_cost = int(selected_stack.item.value) * int(quantity_spin_box.value)
		purchase_button.disabled = total_cost > hero.inventory.gold
	else:
		purchase_button.disabled = true

func _on_shop_manager_hero_updated(hero_ref: Hero) -> void:
	if hero_ui.hero:
		hero_ui.refresh()
	else:
		hero_ui.hero = hero_ref
	var inventory_text = "Hero Inventory: "
	if hero_ref.inventory.potions.size():
		inventory_text += "\n  Potions:"
		for potion_stack in hero_ref.inventory.potions:
			inventory_text += "\n - %s x%d" % [potion_stack.item.name, potion_stack.count]
	else:
		inventory_text += "\n  None"
	inventory_label.text = inventory_text
	
func _on_spin_box_value_changed(_value: float) -> void:
	_update_item_cost()
	_update_purchase_button()

func _on_purchase_button_pressed() -> void:
	if not shop_manager.item_stack_selected or not shop_manager.item_stack_selected.item:
		return

	shop_manager.buy_item(int(quantity_spin_box.value))
	_update_item_list()

func _on_exit_button_pressed() -> void:
	ScreenManager.go_back(LOCATION_ID)
