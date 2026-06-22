extends Control
class_name ShopWindow

signal closed

enum ShopType { POTION, WEAPON }

@onready var shop_manager: ShopManager = $ShopManager
@onready var shop_name_label: Label = $PanelContainer/VBoxContainer/ShopNameLabel
@onready var item_list: VBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer/ScrollContainer/ItemList
# Detail Panel
@onready var item_name_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/ItemNameLabel
@onready var item_description_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/ItemDescriptionLabel
@onready var item_cost_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/CostContainer/ItemCostLabel
@onready var quantity_spin_box: SpinBox = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/CostContainer/QuantitySpinBox
@onready var ability_container: VBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/ability_container
@onready var purchase_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/HBoxContainer/PurchaseButton
# Hero Panel
@onready var hero_ui: HeroInfo = $PanelContainer/VBoxContainer/HBoxContainer/HeroInfo/HeroUI
@onready var inventory_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/HeroInfo/InventoryLabel

const ITEM_BUTTON := preload("res://scenes/ui/components/item_button.tscn")

var hero: Hero
var shop: Shop
var shop_type: ShopType

func open(type: ShopType) -> void:
	shop_type = type
	hero = GameState.hero
	shop = _get_shop()
	shop_manager.start_shop(hero, shop)
	shop_name_label.text = shop.name
	quantity_spin_box.visible = shop_type == ShopType.POTION
	_update_item_list()
	show()

func close() -> void:
	hide()
	closed.emit()

func _get_shop() -> Shop:
	match shop_type:
		ShopType.WEAPON:
			return GameState.village.weapon_shop
		_:
			return GameState.village.potion_shop

# ─── List ────────────────────────────────────────────────────────────────────

func empty_item_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

func create_item_button(item_id: String, count: int) -> Button:
	var button := ITEM_BUTTON.instantiate()
	button.item_id = item_id
	button.count = count
	button.connect("item_pressed", _on_item_pressed)
	return button

func _update_item_list() -> void:
	empty_item_list()
	for item_id in shop.inventory:
		var count: int = shop.inventory[item_id]
		var button := create_item_button(item_id, count)
		item_list.add_child(button)
	if shop_manager.selected_item_id != "" and shop.inventory.has(shop_manager.selected_item_id):
		_on_item_pressed(shop_manager.selected_item_id)
	else:
		_clear_detail_panel()

# ─── Detail Panel ─────────────────────────────────────────────────────────────

func _on_item_pressed(item_id: String) -> void:
	shop_manager.selected_item_id = item_id
	_refresh_detail_panel(item_id)

func _refresh_detail_panel(item_id: String) -> void:
	var item := ItemLoader.get_item(item_id)
	if item == null:
		_clear_detail_panel()
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

func _clear_detail_panel() -> void:
	item_name_label.text = ""
	item_description_label.text = ""
	item_cost_label.text = ""
	purchase_button.disabled = true
	for child in ability_container.get_children():
		child.queue_free()

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
		var qty := int(quantity_spin_box.value) if shop_type == ShopType.POTION else 1
		item_cost_label.text = str(item.value * qty)
		
func _update_purchase_button() -> void:
	var item := ItemLoader.get_item(shop_manager.selected_item_id)
	if item:
		var qty := int(quantity_spin_box.value) if shop_type == ShopType.POTION else 1
		purchase_button.disabled = not shop_manager.can_buy_selected(qty)
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
		text += "\n None"
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
	AudioManager.play_sfx_by_id("bag_of_coins")
	_update_item_list()

func _on_close_button_pressed() -> void:
	close()
