extends Control

@onready var battle_manager = $BattleManager

# Top Bar
@onready var quest_bar = $TopBar/QuestProgressBar
@onready var victory_popup = $BattleVictoryPopup

# Battle Field
@onready var hero_ui = $BattleField/HeroUI
@onready var monster_ui = $BattleField/MonsterUI

# Action Area
@onready var ability_button = $ActionArea/LeftPanel/AbilityButton
@onready var item_button = $ActionArea/LeftPanel/ItemButton
@onready var rest_button = $ActionArea/LeftPanel/RestButton
@onready var flee_button = $ActionArea/LeftPanel/FleeButton

@onready var option_list = $ActionArea/MiddlePanel/OptionList

var AbilityButton := preload("res://scenes/ui/components/ability_button.tscn")
var ItemButton := preload("res://scenes/ui/components/item_button.tscn")

var hero: Hero
var monster: Monster
var current_quest: Quest

func _ready() -> void:
	hero = GameState.hero
	current_quest = GameState.current_quest

	victory_popup.continue_pressed.connect(_on_victory_popup_continue_pressed)
	victory_popup.retreat_pressed.connect(_on_victory_popup_retreat_pressed)
	ability_button.toggled.connect(_on_ability_button_toggled)
	item_button.toggled.connect(_on_item_button_toggled)
	rest_button.pressed.connect(_on_rest_button_pressed)
	flee_button.pressed.connect(_on_flee_button_pressed)

	battle_manager.player_turn.connect(_on_player_turn)
	battle_manager.monster_turn.connect(_on_monster_turn)
	battle_manager.quest_completed.connect(_on_quest_completed)
	battle_manager.hero_defeated.connect(_on_hero_defeated)
	battle_manager.battle_log_updated.connect(_on_battle_log_updated)
	battle_manager.hero_updated.connect(_on_hero_updated)
	battle_manager.monster_updated.connect(_on_monster_updated)
	battle_manager.new_monster.connect(_on_new_monster)
	battle_manager.monster_slain.connect(_on_monster_slain)

	empty_option_list()
	battle_manager.start_battle(hero, current_quest)

func _on_battle_log_updated(msg: String) -> void:
	$ActionArea/BattleLog.append_text(msg + "\n")

func _on_hero_updated(hero_ref: Hero) -> void:
	hero_ui.set_hero_info(hero_ref)

func _on_monster_updated(monster_ref: Monster) -> void:
	monster_ui.set_monster_info(monster_ref)

func _on_new_monster(monster_ref: Monster) -> void:
	monster = monster_ref
	monster_ui.set_monster_info(monster)

func _on_monster_slain(monster_name: String) -> void:
	print("%s was slain!" % monster_name)
	quest_bar.update_bar()
	victory_popup.popup_centered()

func _on_ability_button_toggled(button_pressed: bool):
	if button_pressed:
		item_button.button_pressed = false
		option_list.visible = true
		empty_option_list()
		for ability: Ability in hero.inventory.weapon.abilities:
			var btn = create_ability_button(ability)
			option_list.add_child(btn)
	else:
		option_list.visible = false

func _on_item_button_toggled(button_pressed: bool):
	if button_pressed:
		ability_button.button_pressed = false
		option_list.visible = true
		empty_option_list()
		for item_stack: ItemStack in hero.inventory.potions:
			var btn = create_item_button(item_stack)
			option_list.add_child(btn)
	else:
		option_list.visible = false

func _on_rest_button_pressed() -> void:
	option_list.visible = false
	battle_manager.rest()

func _on_flee_button_pressed() -> void:
	ScreenManager.go_to_screen("village")

func _on_player_turn():
	ability_button.disabled = false
	item_button.disabled = false if hero.inventory.potions.size() > 0 else true
	if hero.rest_cooldown > 0:
		rest_button.disabled = true
		rest_button.text = "Rest CD: %d" % hero.rest_cooldown
	else:
		rest_button.disabled = false
		rest_button.text = "Rest"
	flee_button.disabled = false

func _on_monster_turn():
	ability_button.disabled = true
	item_button.disabled = true
	rest_button.disabled = true
	flee_button.disabled = true

func _on_quest_completed():
	print("Quest completed!")
	if GameState.quest_manager.active_quests.is_empty():
		ScreenManager.go_to_screen("victory")
	else:
		ScreenManager.go_to_screen("quest_finished")

func _on_hero_defeated():
	print("Hero defeated!")
	ScreenManager.go_to_screen("defeat")

func _on_victory_popup_continue_pressed() -> void:
	battle_manager.get_new_monster()
	battle_manager.start_player_turn()

func _on_victory_popup_retreat_pressed() -> void:
	ScreenManager.go_to_screen("village")

func _on_ability_button_pressed(ability: Ability) -> void:
	print("Ability pressed: ", ability.name)
	battle_manager.player_ability_selected(ability)
	ability_button.button_pressed = false

func _on_item_button_pressed(item_stack: ItemStack) -> void:
	print("Item pressed: ", item_stack.item.name)
	battle_manager.player_item_selected(item_stack)
	item_button.button_pressed = false

func empty_option_list() -> void:
	for child in option_list.get_children():
			child.queue_free()

func create_ability_button(ability: Ability) -> Button:
	var button := AbilityButton.instantiate()
	# Set the button theme
	if ability is AttackAbility:
		button.theme = preload("res://assets/button_themes/regular/red_button.tres")
	elif ability is UtilityAbility:
		button.theme = preload("res://assets/button_themes/regular/green_button.tres")
	else:
		button.theme = preload("res://assets/button_themes/regular/gray_button.tres")
	# Set the button text
	var button_text = ability.name
	if ability.energy_cost > hero.current_nrg:
		button_text += " [low nrg]"
		button.disabled = true
	elif ability.is_ready():
		button.tooltip_text = ability.get_tooltip()
	else:
		button_text += " cd: " + str(ability.current_cooldown)
		button.disabled = true
	button.custom_minimum_size = Vector2(96, 32)
	button.ability = ability
	button.text = button_text
	button.connect("ability_pressed", Callable(self, "_on_ability_button_pressed"))
	return button

func create_item_button(item_stack: ItemStack) -> Button:
	var button := ItemButton.instantiate()
	button.item_stack = item_stack
	button.connect("item_pressed", Callable(self, "_on_item_button_pressed"))
	return button
