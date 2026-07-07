extends Button
class_name HeroPreview

@onready var class_name_label: Label = $MarginContainer/VBoxContainer/ClassNameLabel
@onready var weapon_label: Label = $MarginContainer/VBoxContainer/WeaponLabel
@onready var preview_sprite: AnimatedSprite2D = $MarginContainer/VBoxContainer/PreviewContainer/PreviewSprite

signal class_selected(selected_class: Hero.HeroClass)

@export var hero: Hero:
	set(value):
		hero = value
		_update_preview()

var selected := false:
	set(value):
		selected = value
		_update_animation_state()

func _ready() -> void:
	toggle_mode = true
	_update_preview()

func _on_pressed() -> void:
	if hero != null:
		class_selected.emit(hero.hero_class)

func _update_preview() -> void:
	if hero == null or not is_node_ready():
		return
	class_name_label.text = hero.get_class_name()
	if hero.inventory != null and hero.inventory.equipped_weapon != null:
		weapon_label.text = hero.inventory.equipped_weapon.name
	else:
		weapon_label.text = ""
	
	preview_sprite.sprite_frames = hero.battle_visual
	preview_sprite.animation = "idle"
	preview_sprite.frame = 0
	preview_sprite.centered = true
	preview_sprite.scale = Vector2(2.0, 2.0)
	
	_update_animation_state()

func _update_animation_state() -> void:
	if not is_node_ready() or preview_sprite == null:
		return
	button_pressed = selected
	if selected:
		if preview_sprite.sprite_frames != null:
			preview_sprite.play("idle")
	else:
		preview_sprite.stop()
		preview_sprite.frame = 0
