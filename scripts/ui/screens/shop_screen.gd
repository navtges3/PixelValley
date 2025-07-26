extends Control

@onready var shop_manager = $ShopManager

@onready var item_list = $HBoxContainer/ScrollContainer/ItemList

# Detail Panel
@onready var item_name_label = $HBoxContainer/DetailPanel/ItemNameLabel
@onready var item_description_label = $HBoxContainer/DetailPanel/ItemDescriptionLabel
@onready var item_cost_label = $HBoxContainer/DetailPanel/HBoxContainer/ItemCostLabel
@onready var quantity_spin_box = $HBoxContainer/DetailPanel/HBoxContainer/SpinBox

@onready var purchase_button = $HBoxContainer/DetailPanel/PurchaseButton
@onready var exit_button = $HBoxContainer/DetailPanel/ExitButton

@onready var hero_ui = $HBoxContainer/VBoxContainer/HeroUI
@onready var inventory_label = $HBoxContainer/VBoxContainer/InventoryLabel

var hero: HeroInstance
var shop: Shop

func _ready() -> void:
	hero = GameState.hero
	shop = GameState.village.shop

	exit_button.pressed.connect(_on_exit_button_pressed)

	shop_manager.start_shop(hero, shop)

func _on_hero_updated(hero_ref: HeroInstance) -> void:
	hero_ui.set_hero_info(hero_ref)

func _on_exit_button_pressed() -> void:
	ScreenManager.go_to_screen("village")