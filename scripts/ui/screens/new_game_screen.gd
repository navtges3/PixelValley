extends Control

@onready var new_game_window: Window = $NewGameWindow

@onready var hero_class = $VBoxContainer/HBoxContainer/HeroInfoContainer/HeroClassLabel
@onready var hero_name = $VBoxContainer/HBoxContainer/HeroInfoContainer/HeroName

@onready var class_selector = $VBoxContainer/ClassSelector

@onready var back_button = $VBoxContainer/ButtonContainer/BackButton
@onready var create_button = $VBoxContainer/ButtonContainer/CreateButton

const PREVIEW_SCENE = preload("res://scenes/ui/components/hero_preview.tscn")

const HERO_DEFAULTS = [
	"res://resources/characters/heroes/knight/knight.tres",
	"res://resources/characters/heroes/assassin/assassin.tres",
	"res://resources/characters/heroes/princess/princess.tres",
]

var hero_selected: Hero = null

func _ready() -> void:
	hero_class.text = ""
	hero_name.text = ""
	load_hero_previews()

func load_hero_previews() -> void:
	for path in HERO_DEFAULTS:
		var hero_preview = load(path) as Hero
		if hero_preview:
			var preview = PREVIEW_SCENE.instantiate()
			preview.hero = hero_preview
			preview.class_selected.connect(_on_class_selected)
			class_selector.add_child(preview)

func check_create_button_state():
	if hero_class.text != "" and hero_name.text != "":
		create_button.disabled = false
	else:
		create_button.disabled = true

func _on_class_selected(selected_class: Hero) -> void:
	if hero_selected == selected_class:
		hero_selected = null
		hero_class.text = ""
		print("Deselected class")
	else:
		hero_selected = selected_class
		hero_class.text = selected_class.get_class_name()
		print("Selected class: ", hero_selected.get_class_name())
	check_create_button_state()

func _on_back_button_pressed() -> void:
	GameState.hero = null
	ScreenManager.go_to_screen(ScreenManager.ScreenName.MAIN_MENU)

func _on_create_button_pressed() -> void:
	var new_hero = hero_selected.duplicate()
	new_hero.name = hero_name.text
	GameState.hero = new_hero
	new_game_window.popup_centered()

func _on_hero_name_text_changed(_new_text: String) -> void:
	check_create_button_state()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_submit") and not create_button.disabled:
		_on_create_button_pressed()
