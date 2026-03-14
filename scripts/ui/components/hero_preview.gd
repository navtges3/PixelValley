extends Control

@onready var click_area = $ClickArea

signal class_selected(selected_class: Hero)

@export var hero: Hero:
	set(value):
		hero = value
		_update_preview()

func _on_click_area_pressed() -> void:
	if hero:
		emit_signal("class_selected", hero)

func _update_preview() -> void:
	if not hero:
		return
	$VBoxContainer/ClassNameLabel.text = hero.get_class_name()
	$VBoxContainer/Portrait.texture = hero.portrait
	$VBoxContainer/WeaponLabel.text = hero.inventory.equipped_weapon.name
