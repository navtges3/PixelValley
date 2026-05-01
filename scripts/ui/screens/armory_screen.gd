extends Control

const LOCATION_ID := "armory"

@onready var item_list: VBoxContainer = $HBoxContainer/LeftPanelContainer/LeftPanel/ItemList
@onready var equip_button: Button = $HBoxContainer/LeftPanelContainer/LeftPanel/Buttons/EquipButton

@onready var name_label: Label = $HBoxContainer/RightPanelContainer/RightPanel/NameLabel
@onready var description_label: Label = $HBoxContainer/RightPanelContainer/RightPanel/DescriptionLabel
@onready var ability_container: VBoxContainer = $HBoxContainer/RightPanelContainer/RightPanel/AbilityContainer

var ItemButton := preload("res://scenes/ui/components/item_button.tscn")

var hero: Hero
var selected_weapon_id: String

func _ready() -> void:
	hero = GameState.hero
	_update_weapon_list()

func _update_weapon_list() -> void:
	_empty_item_list()
	var equipped_id := ItemLoader.get_item_id(hero.inventory.equipped_weapon)
	selected_weapon_id = equipped_id
	_add_weapon_button(equipped_id)
	for weapon_id in hero.inventory.weapon_stash:
		_add_weapon_button(weapon_id)
	_update_right_panel()
	_update_equip_button()

func _add_weapon_button(weapon_id: String) -> void:
	var button := ItemButton.instantiate()
	button.item_id = weapon_id
	button.count = 1
	button.connect("item_pressed", Callable(self, "_on_item_pressed"))
	item_list.add_child(button)

func _on_item_pressed(item_id: String) -> void:
	selected_weapon_id = item_id
	_update_right_panel()
	_update_equip_button()

func _update_right_panel() -> void:
	var weapon := ItemLoader.get_item(selected_weapon_id) as Weapon
	if weapon == null:
		return
	name_label.text = weapon.name
	description_label.text = weapon.description
	_empty_ability_list()
	for ability in weapon.abilities:
		var label = Label.new()
		label.text = "- %s" % ability.name
		ability_container.add_child(label)

func _update_equip_button() -> void:
	var equipped_id := ItemLoader.get_item_id(hero.inventory.equipped_weapon)
	equip_button.disabled = selected_weapon_id == equipped_id

func _on_equip_button_pressed() -> void:
	if selected_weapon_id != "":
		hero.inventory.equip_weapon(selected_weapon_id)
		_update_weapon_list()

func _on_back_button_pressed() -> void:
	ScreenManager.go_back(LOCATION_ID)

func _empty_ability_list() -> void:
	for child in ability_container.get_children():
		child.queue_free()

func _empty_item_list() -> void:
	for child in item_list.get_children():
		child.queue_free()
