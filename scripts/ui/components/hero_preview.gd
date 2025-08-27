extends Control

@onready var click_area = $ClickArea

var hero: Hero = null
signal class_selected(selected_class: Hero)

func _ready() -> void:
	click_area.pressed.connect(_on_click_area_pressed)

func set_hero_class(new_hero: Hero) -> void:
	hero = new_hero
	print("Setting hero class:", hero.hero_class)
	_update_preview()

func _on_click_area_pressed() -> void:
	if hero:
		emit_signal("class_selected", hero)

func _update_preview() -> void:
	if not hero:
		return

	$VBoxContainer/ClassNameLabel.text = hero.hero_class
	$VBoxContainer/Portrait.texture = hero.portrait
	$VBoxContainer/WeaponLabel.text = hero.inventory.weapon.name
