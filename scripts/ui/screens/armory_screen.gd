extends Control

@onready var item_list: VBoxContainer = $HBoxContainer/LeftPanelContainer/LeftPanel/ItemList
@onready var equip_button: Button = $HBoxContainer/LeftPanelContainer/LeftPanel/Buttons/EquipButton

@onready var name_label: Label = $HBoxContainer/RightPanelContainer/RightPanel/NameLabel
@onready var description_label: Label = $HBoxContainer/RightPanelContainer/RightPanel/DescriptionLabel
@onready var ability_container: VBoxContainer = $HBoxContainer/RightPanelContainer/RightPanel/AbilityContainer

var ItemButton := preload("res://scenes/ui/components/item_button.tscn")

var hero: Hero
var selected_weapon: Weapon

func _ready() -> void:
	hero = GameState.hero
	_update_weapon_list()

func _update_weapon_list() -> void:
	empty_item_list()
	selected_weapon = hero.inventory.equipped_weapon
	var equipped_weapon_button = create_item_button(hero.inventory.equipped_weapon)
	item_list.add_child(equipped_weapon_button)
	for weapon in hero.inventory.weapon_stash:
		var button = create_item_button(weapon)
		item_list.add_child(button)
	_update_right_panel()
	_update_equip_button()

func _on_item_pressed(item_stack: ItemStack) -> void:
	selected_weapon = item_stack.item as Weapon
	_update_right_panel()
	_update_equip_button()

func _update_right_panel() -> void:
	name_label.text = selected_weapon.name
	description_label.text = selected_weapon.description
	empty_ability_list()
	for ability in selected_weapon.abilities:
		var label = Label.new()
		label.text = "- %s" % ability.name
		ability_container.add_child(label)

func _update_equip_button() -> void:
	if selected_weapon == hero.inventory.equipped_weapon:
		equip_button.disabled = true
	else:
		equip_button.disabled = false

func _on_equip_button_pressed() -> void:
	if selected_weapon:
		hero.inventory.equip_weapon(selected_weapon)
		_update_weapon_list()

func _on_back_button_pressed() -> void:
	ScreenManager.go_back("armory")

func empty_ability_list() -> void:
	for child in ability_container.get_children():
		child.queue_free()

func empty_item_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

func create_item_button(item: Item) -> Button:
	var button := ItemButton.instantiate()
	var item_stack := ItemStack.new(item, 1)
	button.item_stack = item_stack
	button.connect("item_pressed", Callable(self, "_on_item_pressed"))
	return button
