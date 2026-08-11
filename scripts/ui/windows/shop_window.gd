extends GameWindow
class_name ShopWindow

enum ShopType { POTION, WEAPON }

@onready var shop_manager: ShopManager = $ShopManager
@onready var shop_name_label: Label = $PanelContainer/VBoxContainer/ShopNameLabel
@onready var item_list: VBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer/ScrollContainer/ItemList
# Detail Panel
@onready var item_name_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/ItemNameLabel
@onready var item_description_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/ItemDescriptionLabel
@onready var item_cost_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/ItemCostLabel
@onready var quantity_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/QuantityContainer/QuantityLabel
@onready var quantity_slider: HSlider = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/QuantityContainer/QuantitySlider
@onready var ability_container: VBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/ability_container
@onready var purchase_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/HBoxContainer/PurchaseButton
@onready var close_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/ItemContainer/HBoxContainer/CloseButton
# Hero Panel
@onready var hero_ui: HeroInfo = $PanelContainer/VBoxContainer/HBoxContainer/HeroInfo/HeroUI
@onready var inventory_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/HeroInfo/InventoryLabel

const ITEM_BUTTON := preload("res://scenes/ui/components/item_button.tscn")

var hero: Hero
var shop: Shop
var shop_type: ShopType
var _item_buttons: Array[ItemButton] = []

func open() -> void:
	_update_item_list()
	var world_hud := ScreenManager.get_world_hud() as WorldHUD
	if world_hud != null:
		world_hud.set_hero_hud_visible(false)
	super.open()

func close() -> void:
	var world_hud := ScreenManager.get_world_hud() as WorldHUD
	if world_hud != null:
		world_hud.set_hero_hud_visible(true)
	super.close()

func setup_shop(type: ShopType) -> void:
	shop_type = type
	shop = _get_shop()
	hero = GameState.hero
	shop_manager.start_shop(hero, shop)
	shop_name_label.text = shop.name
	quantity_label.visible = shop_type == ShopType.POTION
	quantity_slider.visible = shop_type == ShopType.POTION

func _get_shop() -> Shop:
	match shop_type:
		ShopType.WEAPON:
			return GameState.village.weapon_shop
		_:
			return GameState.village.potion_shop

func _get_default_focus_target() -> Control:
	for child: Node in item_list.get_children():
		if (
			child is Button and
			not child.is_queued_for_deletion() and
			not (child as Button).disabled
		):
			return child as Button
	return close_button

# ─── List ────────────────────────────────────────────────────────────────────

func empty_item_list() -> void:
	for child: Node in item_list.get_children():
		item_list.remove_child(child)
		child.queue_free()
	_item_buttons.clear()

func create_item_button(item_id: String, count: int) -> ItemButton:
	var button := ITEM_BUTTON.instantiate() as ItemButton
	button.item_id = item_id
	button.count = count
	button.item_pressed.connect(_on_item_pressed)
	button.focus_entered.connect(_on_item_focused.bind(item_id))
	return button

func _update_item_list() -> void:
	empty_item_list()
	for item_id: String in shop.inventory:
		var count: int = shop.inventory[item_id]
		var button: ItemButton = create_item_button(item_id, count)
		item_list.add_child(button)
		_item_buttons.append(button)
	if shop_manager.selected_item_id != "" and shop.inventory.has(shop_manager.selected_item_id):
		_on_item_pressed(shop_manager.selected_item_id)
	else:
		_clear_detail_panel()
	_configure_focus_graph()

func _configure_focus_graph() -> void:
	if _item_buttons.is_empty():
		close_button.focus_neighbor_top = close_button.get_path_to(close_button)
		close_button.focus_neighbor_right = close_button.get_path_to(close_button)
		return

	var detail_target: Control = close_button
	if shop_type == ShopType.POTION:
		detail_target = quantity_slider
	elif not purchase_button.disabled:
		detail_target = purchase_button

	for index: int in _item_buttons.size():
		var button: ItemButton = _item_buttons[index]
		var top_target: ItemButton = button
		var bottom_target: Control = close_button
		if index > 0:
			top_target = _item_buttons[index - 1]
		if index < _item_buttons.size() - 1:
			bottom_target = _item_buttons[index + 1]
		button.focus_neighbor_top = button.get_path_to(top_target)
		button.focus_neighbor_bottom = button.get_path_to(bottom_target)
		button.focus_neighbor_right = button.get_path_to(detail_target)

	var selected_button: ItemButton = _get_selected_item_button()
	var list_return_target: Control = (
		selected_button if selected_button != null else _item_buttons[0]
	)
	quantity_slider.focus_neighbor_top = quantity_slider.get_path_to(list_return_target)
	quantity_slider.focus_neighbor_bottom = quantity_slider.get_path_to(
		purchase_button if not purchase_button.disabled else close_button
	)
	close_button.focus_neighbor_top = close_button.get_path_to(list_return_target)
	close_button.focus_neighbor_right = close_button.get_path_to(
		purchase_button if not purchase_button.disabled else close_button
	)
	purchase_button.focus_neighbor_left = purchase_button.get_path_to(close_button)
	purchase_button.focus_neighbor_top = purchase_button.get_path_to(
		quantity_slider if shop_type == ShopType.POTION else list_return_target
	)

func _get_selected_item_button() -> ItemButton:
	for button: ItemButton in _item_buttons:
		if button.item_id == shop_manager.selected_item_id:
			return button
	return null

# ─── Detail Panel ─────────────────────────────────────────────────────────────

func _on_item_pressed(item_id: String) -> void:
	shop_manager.selected_item_id = item_id
	_refresh_detail_panel(item_id)

func _on_item_focused(item_id: String) -> void:
	if shop_manager.selected_item_id == item_id:
		return
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
		quantity_slider.max_value = float(shop.inventory.get(item_id, 1))
		quantity_slider.set_value_no_signal(1.0)
		quantity_label.text = "1"
	elif shop_type == ShopType.WEAPON:
		_refresh_ability_list(item as Weapon)
	_update_item_cost()
	_update_purchase_button()
	_configure_focus_graph()

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
		var qty := int(quantity_slider.value) if shop_type == ShopType.POTION else 1
		item_cost_label.text = str(item.value * qty)
		
func _update_purchase_button() -> void:
	var item := ItemLoader.get_item(shop_manager.selected_item_id)
	if item:
		var qty := int(quantity_slider.value) if shop_type == ShopType.POTION else 1
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

func _on_quantity_changed(value: float) -> void:
	quantity_label.text = "%d" % int(value)
	_update_item_cost()
	_update_purchase_button()

func _on_purchase_button_pressed() -> void:
	if shop_manager.selected_item_id == "":
		return
	var qty := int(quantity_slider.value) if shop_type == ShopType.POTION else 1
	shop_manager.buy_item(qty)
	AudioManager.play_sfx_by_id("bag_of_coins")
	_update_item_list()
	if purchase_button.disabled and purchase_button.has_focus():
		_apply_default_focus.call_deferred()

func _on_close_button_pressed() -> void:
	close()
