extends Control
class_name HeroPreview

@onready var class_name_label: Label = $VBoxContainer/ClassNameLabel
@onready var weapon_label: Label = $VBoxContainer/WeaponLabel
@onready var preview_sprite: AnimatedSprite2D = $VBoxContainer/PreviewContainer/PreviewSprite

signal class_selected(selected_class: Hero)

@export var hero: Hero:
	set(value):
		hero = value
		_update_preview()

var selected := false:
	set(value):
		selected = value
		_update_animation_state()

func _ready() -> void:
	_update_preview()

func _on_click_area_pressed() -> void:
	if hero:
		class_selected.emit(hero)

func _update_preview() -> void:
	if not hero or not is_node_ready():
		return
	class_name_label.text = hero.get_class_name()
	weapon_label.text = hero.inventory.equipped_weapon.name
	
	preview_sprite.sprite_frames = hero.battle_visual
	preview_sprite.animation = "idle"
	preview_sprite.frame = 0
	preview_sprite.centered = true
	preview_sprite.scale = Vector2(2.0, 2.0)
	
	_update_animation_state()

func _update_animation_state() -> void:
	if not is_node_ready() or not preview_sprite:
		return
	if selected:
		if preview_sprite.sprite_frames:
			preview_sprite.play("idle")
	else:
		preview_sprite.stop()
		preview_sprite.frame = 0
