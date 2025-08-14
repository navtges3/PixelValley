extends Control

@onready var shop_manager = $ShopManager

@onready var item_list = $HBoxContainer/ScrollContainer/ItemList

@onready var shop_name_label = $ShopNameLabel
# Detail Panel
@onready var item_name_label = $HBoxContainer/DetailPanel/ItemNameLabel
@onready var item_description_label = $HBoxContainer/DetailPanel/ItemDescriptionLabel
@onready var item_cost_label = $HBoxContainer/DetailPanel/HBoxContainer/ItemCostLabel
@onready var quantity_spin_box = $HBoxContainer/DetailPanel/HBoxContainer/SpinBox

@onready var purchase_button = $HBoxContainer/DetailPanel/PurchaseButton
@onready var exit_button = $HBoxContainer/DetailPanel/ExitButton

@onready var hero_ui = $HBoxContainer/VBoxContainer/HeroUI
@onready var inventory_label = $HBoxContainer/VBoxContainer/InventoryLabel

var ItemButton := preload("res://scenes/ui/components/item_button.tscn")

var hero: Hero
var shop: Shop

func _ready() -> void:
	hero = GameState.hero
	shop = GameState.village.shop

	exit_button.pressed.connect(_on_exit_button_pressed)
	purchase_button.pressed.connect(_on_purchase_button_pressed)
	quantity_spin_box.value_changed.connect(_on_quantity_changed)

	shop_name_label.text = shop.name
	shop_manager.hero_updated.connect(_on_hero_updated)
	shop_manager.start_shop(hero, shop)
	_update_item_list()

func _update_item_list() -> void:
	empty_item_list()
	for item_stack in shop.inventory:
		var label = Label.new()
		label.text = "%dx" % item_stack.count
		label.custom_minimum_size = Vector2(32, 32)
		item_list.add_child(label)
		var button = create_item_button(item_stack)
		item_list.add_child(button)
	_on_item_selected(shop_manager.item_stack_selected)

func _on_hero_updated(hero_ref: Hero) -> void:
	hero_ui.set_hero_info(hero_ref)
	var inventory_text = "Hero Inventory: "
	if hero_ref.inventory.potions.size():
		inventory_text += "\n  Potions:"
		for potion_stack in hero_ref.inventory.potions:
			inventory_text += "\n - %s x%d" % [potion_stack.item.name, potion_stack.count]
	else:
		inventory_text += "\n  None"
	inventory_label.text = inventory_text

func _on_item_selected(item_stack: ItemStack) -> void:
	item_name_label.text = item_stack.item.name
	item_description_label.text = item_stack.item.description
	item_cost_label.text = str(item_stack.item.value)
	shop_manager.item_stack_selected = item_stack

	quantity_spin_box.value = 1
	quantity_spin_box.max_value = item_stack.count if item_stack and item_stack.item else 1

	_update_purchase_button()

func _on_quantity_changed(_value: float) -> void:
	_update_purchase_button()

func _update_purchase_button() -> void:
	var selected_stack = shop_manager.item_stack_selected
	if selected_stack and selected_stack.item:
		var total_cost = int(selected_stack.item.value) * int(quantity_spin_box.value)
		purchase_button.disabled = total_cost > hero.inventory.gold
	else:
		purchase_button.disabled = true

func _on_purchase_button_pressed() -> void:
	if not shop_manager.item_stack_selected or not shop_manager.item_stack_selected.item:
		return

	shop_manager.buy_item(int(quantity_spin_box.value))
	_update_item_list()

func _on_exit_button_pressed() -> void:
	ScreenManager.go_to_screen("village")

func empty_item_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

func create_item_button(item_stack: ItemStack) -> Button:
	var button := ItemButton.instantiate()
	button.text = item_stack.item.name
	if item_stack.item is Weapon:
		button.theme = preload("res://assets/button_themes/large/large_red_button.tres")
	elif item_stack.item is Potion:
		button.theme = item_stack.item.effect.get_button_theme()
	else:
		button.theme = preload("res://assets/button_themes/large/large_gray_button.tres")
	button.custom_minimum_size = Vector2(96, 32)
	button.item_stack = item_stack
	button.tooltip_text = item_stack.item.get_tooltip()
	button.connect("item_pressed", Callable(self, "_on_item_selected"))
	return button
