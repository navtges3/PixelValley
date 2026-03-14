extends Control

@onready var hero_dropdown: OptionButton = $MarginContainer/VBoxContainer/HeroSelection/HeroDropdown
@onready var monster_spin_box: SpinBox = $MarginContainer/VBoxContainer/MonsterSelection/MonsterSpinBox
@onready var monster_dropdown: OptionButton = $MarginContainer/VBoxContainer/MonsterSelection/MonsterDropdown

var hero_resources: Array[Hero] = []
var monster_resources: Array[Monster] = []

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
		preload("res://resources/characters/monsters/goblin/goblin.tres"),
		preload("res://resources/characters/monsters/orc/orc.tres"),
		preload("res://resources/characters/monsters/orc_chieftain/orc_chieftain.tres"),
	]
	for i in monster_resources.size():
		monster_dropdown.add_item(monster_resources[i].name, i)


func _on_start_battle_pressed() -> void:
	GameState.hero = hero_resources[hero_dropdown.get_selected_id()].duplicate()
	print("Hero selected: ", GameState.hero.name)

	var monster_obj = MonsterRequirement.new()
	monster_obj.monster = monster_resources[monster_dropdown.get_selected_id()]
	monster_obj.target_amount = monster_spin_box.value
	var test_quest = Quest.new()
	test_quest.title = "Test Quest"
	test_quest.monster_objectives.append(monster_obj)

	var config := BattleConfig.new()
	config.hero = GameState.hero
	config.quest = test_quest
	config.is_test_battle = true

	ScreenManager.go_to_screen(ScreenManager.ScreenName.BATTLE, config)


func _on_back_button_pressed() -> void:
	get_tree().quit()
