extends Control

@onready var hero_dropdown: OptionButton = $MarginContainer/VBoxContainer/HeroSelection/HeroDropdown
@onready var monster_spin_box: SpinBox = $MarginContainer/VBoxContainer/MonsterSelection/MonsterSpinBox
@onready var monster_dropdown: OptionButton = $MarginContainer/VBoxContainer/MonsterSelection/MonsterDropdown

var hero_resources: Array[Hero] = []
var monster_resources: Array[MonsterLoader.MonsterID] = []

func _ready():
	load_heroes()
	load_monsters()

func load_heroes():
	hero_resources = [
		preload("res://resources/characters/heroes/knight/knight.tres"),
		preload("res://resources/characters/heroes/princess/princess.tres"),
		preload("res://resources/characters/heroes/assassin/assassin.tres"),
	]
	for i in hero_resources.size():
		hero_dropdown.add_item(hero_resources[i].get_class_name(), i)

func load_monsters():
	monster_resources = [
		MonsterLoader.MonsterID.GOBLIN,
		MonsterLoader.MonsterID.ORC,
		MonsterLoader.MonsterID.ORC_CHIEFTAIN,
		MonsterLoader.MonsterID.OGRE,
		MonsterLoader.MonsterID.OGRE_WARLORD,
		MonsterLoader.MonsterID.OGRE_KING,
	]
	for i in monster_resources.size():
		monster_dropdown.add_item(MonsterLoader.get_monster_name(i))

func _on_start_battle_pressed() -> void:
	var config := BattleConfig.new()
	config.monster_id = monster_resources[monster_dropdown.get_selected_id()]
	config.hero = hero_resources[hero_dropdown.get_selected_id()].duplicate()
	GameState.hero = config.hero
	print("Hero selected: ", GameState.hero.name)
	ScreenManager.go_to_screen(ScreenManager.ScreenName.BATTLE, "", config)

func _on_back_button_pressed() -> void:
	get_tree().quit()
