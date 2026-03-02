extends Control

@onready var hero_dropdown: OptionButton = $MarginContainer/VBoxContainer/HeroSelection/HeroDropdown
@onready var monster_spin_box: SpinBox = $MarginContainer/VBoxContainer/MonsterSelection/MonsterSpinBox
@onready var monster_dropdown: OptionButton = $MarginContainer/VBoxContainer/MonsterSelection/MonsterDropdown

var hero_resources: Array = []
var monster_resources: Array = []

func _ready():
	load_heroes()
	load_monsters()
	
func load_heroes():
	hero_resources = [
		preload("res://resources/heroes/knight/knight.tres"),
	]
	for i in hero_resources.size():
		hero_dropdown.add_item(hero_resources[i].name, i)

func load_monsters():
	monster_resources = [
		preload("res://resources/monsters/goblin/goblin.tres"),
	]
	for i in monster_resources.size():
		monster_dropdown.add_item(monster_resources[i].name, i)


func _on_start_battle_pressed() -> void:
	GameState.hero = hero_resources[hero_dropdown.get_selected_id()]
	
	var monster_obj = MonsterRequirement.new()
	monster_obj.monster = monster_resources[monster_dropdown.get_selected_id()]
	monster_obj.target_amount = monster_spin_box.value
	var test_quest = Quest.new()
	test_quest.monster_objectives.append(monster_obj)
	
	var config := BattleConfig.new()
	config.hero = GameState.hero
	config.quest = test_quest
	config.is_test_battle = true
	
	ScreenManager.go_to_screen(ScreenManager.ScreenName.BATTLE, config)
