extends Control
class_name HeroPreview

@onready var class_name_label: Label = $VBoxContainer/ClassNameLabel
@onready var portrait: TextureRect = $VBoxContainer/Portrait
@onready var weapon_label: Label = $VBoxContainer/WeaponLabel

signal class_selected(selected_class: Hero)

@export var hero: Hero:
	set(value):
		hero = value
		_update_preview()

func _ready() -> void:
	_update_preview()

func _on_click_area_pressed() -> void:
	if hero:
		emit_signal("class_selected", hero)

func _update_preview() -> void:
	if not hero or not is_node_ready():
		return
	class_name_label.text = hero.get_class_name()
	portrait.texture = hero.portrait
	weapon_label.text = hero.inventory.equipped_weapon.name
