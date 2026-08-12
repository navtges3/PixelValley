extends Control
class_name NewGameScreen

@onready var new_game_window: NewGameWindow = $NewGameWindow

@onready var hero_name: LineEdit = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/HeroInfoContainer/HeroName
@onready var hero_class: Label = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/HeroInfoContainer/HeroClassLabel

@onready var class_selector: HBoxContainer = $VBoxContainer/ClassSelector

@onready var back_button: Button = $VBoxContainer/PanelContainer/VBoxContainer/ButtonContainer/BackButton
@onready var create_button: Button = $VBoxContainer/PanelContainer/VBoxContainer/ButtonContainer/CreateButton

const PREVIEW_SCENE = preload("res://scenes/ui/components/hero_preview.tscn")

const HERO_DEFAULTS = [
	"res://resources/characters/heroes/knight/knight.tres",
	"res://resources/characters/heroes/assassin/assassin.tres",
	"res://resources/characters/heroes/princess/princess.tres",
]

var _class_selected := false
var _custom_name_entered: bool = false
var _hero_previews: Array[HeroPreview] = []
var _selected_class: Hero.HeroClass

func _ready() -> void:
	hero_class.text = ""
	hero_name.text = ""
	load_hero_previews()

func load_hero_previews() -> void:
	for path: String in HERO_DEFAULTS:
		var hero_data := load(path) as Hero
		if hero_data == null:
			continue
		var preview := PREVIEW_SCENE.instantiate() as HeroPreview
		preview.hero = hero_data
		preview.class_selected.connect(_on_class_selected)
		class_selector.add_child(preview)
		_hero_previews.append(preview)
	_configure_focus_graph()
	if not _hero_previews.is_empty():
		_hero_previews[0].grab_focus.call_deferred()

func check_create_button_state() -> void:
	create_button.disabled = not (
		_class_selected and not hero_name.text.strip_edges().is_empty()
	)
	_configure_focus_graph()

func _configure_focus_graph() -> void:
	if _hero_previews.is_empty():
		hero_name.focus_neighbor_bottom = hero_name.get_path_to(back_button)
		return

	for index: int in _hero_previews.size():
		var preview: HeroPreview = _hero_previews[index]
		var left_target: HeroPreview = preview
		var right_target: HeroPreview = preview
		if index > 0:
			left_target = _hero_previews[index - 1]
		if index < _hero_previews.size() - 1:
			right_target = _hero_previews[index + 1]
		preview.focus_neighbor_left = preview.get_path_to(left_target)
		preview.focus_neighbor_right = preview.get_path_to(right_target)
		preview.focus_neighbor_bottom = preview.get_path_to(hero_name)

	var preview_target: HeroPreview = _get_selected_preview()
	hero_name.focus_neighbor_top = hero_name.get_path_to(preview_target)
	hero_name.focus_neighbor_bottom = hero_name.get_path_to(
		create_button if not create_button.disabled else back_button
	)
	back_button.focus_neighbor_top = back_button.get_path_to(hero_name)
	back_button.focus_neighbor_right = back_button.get_path_to(
		create_button if not create_button.disabled else back_button
	)
	create_button.focus_neighbor_top = create_button.get_path_to(hero_name)
	create_button.focus_neighbor_left = create_button.get_path_to(back_button)

func _get_selected_preview() -> HeroPreview:
	for preview: HeroPreview in _hero_previews:
		if preview.selected:
			return preview
	return _hero_previews[0]

func _get_class_name(selected_class: Hero.HeroClass) -> String:
	match selected_class:
		Hero.HeroClass.ASSASSIN:
			return "Assassin"
		Hero.HeroClass.KNIGHT:
			return "Knight"
		Hero.HeroClass.PRINCESS:
			return "Princess"
		_:
			return "Unknown"

func _on_back_button_pressed() -> void:
	GameState.hero = null
	ScreenManager.go_to_screen(ScreenManager.ScreenName.MAIN_MENU)

func _on_class_selected(selected_class: Hero.HeroClass) -> void:
	if _class_selected and _selected_class == selected_class:
		_class_selected = false
		hero_class.text = ""
	else:
		_class_selected = true
		_selected_class = selected_class
		hero_class.text = _get_class_name(selected_class)
	_update_preview_selection()
	if not _custom_name_entered:
		hero_name.text = _get_class_name(selected_class)
	check_create_button_state()

func _on_create_button_pressed() -> void:
	var new_hero := HeroLoader.new_hero(_selected_class)
	new_hero.name = hero_name.text
	GameState.hero = new_hero
	new_game_window.open()

func _on_hero_name_text_changed(_new_text: String) -> void:
	_custom_name_entered = true
	check_create_button_state()

func _on_hero_name_text_submitted(_new_text: String) -> void:
	hero_name.unedit()
	if not create_button.disabled:
		create_button.grab_focus()
	else:
		back_button.grab_focus()

func _update_preview_selection() -> void:
	for child in class_selector.get_children():
		if child is HeroPreview and child.hero != null:
			child.selected = _class_selected and child.hero.hero_class == _selected_class

func _unhandled_input(event: InputEvent) -> void:
	if new_game_window.is_open():
		return
	if not event.is_echo() and event.is_action_pressed(&"ui_cancel"):
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()
