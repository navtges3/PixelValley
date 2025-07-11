extends Control

@onready var click_area = $ClickArea

var hero_class: HeroClass = null
signal class_selected(selected_class: HeroClass)

func _ready() -> void:
	click_area.pressed.connect(_on_click_area_pressed)

func set_hero_class(new_class: HeroClass) -> void:
	hero_class = new_class
	print("Setting hero class:", hero_class.hero_class_name)
	_update_preview()

func _on_click_area_pressed() -> void:
	if hero_class:
		emit_signal("class_selected", hero_class)

func _update_preview() -> void:
	if not hero_class:
		return

	$VBoxContainer/ClassNameLabel.text = hero_class.hero_class_name
	$VBoxContainer/Portrait.texture = hero_class.portrait
	$VBoxContainer/WeaponLabel.text = hero_class.base_weapon.name
