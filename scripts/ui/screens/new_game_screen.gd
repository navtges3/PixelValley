extends Control

@onready var new_game_popup: PopupPanel = $NewGamePopup

@onready var hero_class = $VBoxContainer/HBoxContainer/HeroInfoContainer/HeroClassLabel
@onready var hero_name = $VBoxContainer/HBoxContainer/HeroInfoContainer/HeroName

@onready var class_selector = $VBoxContainer/ClassSelector

@onready var back_button = $VBoxContainer/ButtonContainer/Back
@onready var create_button = $VBoxContainer/ButtonContainer/Create

const PREVIEW_SCENE = preload("res://scenes/ui/components/hero_preview.tscn")

const HERO_DEFAULTS = [
	"res://resources/heroes/knight/knight.tres",
	"res://resources/heroes/assassin.tres",
	"res://resources/heroes/princess.tres",
]

var hero_selected: Hero = null

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	create_button.pressed.connect(_on_create_button_pressed)
	hero_name.text_changed.connect(_on_line_edit_text_changed)

	create_button.disabled = true
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
	new_game_popup.popup_centered()

func _on_line_edit_text_changed(_new_text):
	check_create_button_state()

func check_create_button_state():
	if hero_class.text != "" and hero_name.text != "":
		create_button.disabled = false
	else:
		create_button.disabled = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_submit") and not create_button.disabled:
		_on_create_button_pressed()
