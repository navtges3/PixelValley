extends Control

@onready var battle_manager = $BattleManager

# Top Bar
@onready var village_hp_bar = $TopBar/VillageHPBar
@onready var quest_bar = $TopBar/QuestProgressBar
@onready var pause_button = $TopBar/PauseButton
@onready var pause_popup = $PausePopup
@onready var victory_popup = $BattleVictoryPopup

# Battle Field
@onready var hero_ui = $BattleField/HeroUI
@onready var monster_ui = $BattleField/MonsterUI

# Action Area
@onready var ability_button = $ActionArea/LeftPanel/AbilityButton
@onready var item_button = $ActionArea/LeftPanel/ItemButton
@onready var rest_button = $ActionArea/LeftPanel/RestButton
@onready var flee_button = $ActionArea/LeftPanel/FleeButton

@onready var ability_option_list = $ActionArea/MiddlePanel/OptionList

var hero: HeroInstance
var monster: Monster
var current_quest: Quest

func _ready() -> void:
	hero = GameState.hero
	current_quest = GameState.current_quest

	victory_popup.continue_button.pressed.connect(_on_victory_popup_continue_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	ability_button.toggled.connect(_on_ability_button_toggled)
	rest_button.pressed.connect(_on_rest_button_pressed)
	flee_button.pressed.connect(_on_flee_button_pressed)

	battle_manager.monster_slain.connect(_on_monster_slain)
	battle_manager.new_monster.connect(_on_new_monster)
	battle_manager.player_turn.connect(_on_player_turn)
	battle_manager.monster_turn.connect(_on_monster_turn)
	battle_manager.quest_completed.connect(_on_quest_completed)
	battle_manager.hero_defeated.connect(_on_hero_defeated)
	battle_manager.battle_log_updated.connect(_on_battle_log_updated)
	battle_manager.hero_updated.connect(_on_hero_updated)
	battle_manager.monster_updated.connect(_on_monster_updated)

	battle_manager.start_battle(hero, current_quest)

func _on_battle_log_updated(msg: String) -> void:
	$ActionArea/BattleLog.append_text(msg + "\n")

func _on_hero_updated(hero_ref: HeroInstance) -> void:
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
		print("toggled")
		ability_option_list.visible = true
		# Clear prefious buttons
		for child in ability_option_list.get_children():
			child.queue_free()
		# Add a new button for each ability
		for ability: Ability in hero.weapon.abilities:
			var action_text: String = ability.name
			var btn = Button.new()
			if not ability.is_ready():
				action_text += " cd: " + str(ability.current_cooldown)
				btn.disabled = true
			else:
				btn.tooltip_text = "Energy: %d\nCooldown: %d turns" % [ability.energy_cost, ability.cooldown]
			btn.text = action_text
			btn.theme = preload("res://assets/button_themes/large/large_red_button.tres")
			btn.custom_minimum_size = Vector2(96, 32)
			btn.pressed.connect(_on_ability_selected.bind(action_text))
			ability_option_list.add_child(btn)
	else:
		print("not toggled")
		ability_option_list.visible = false

func _on_ability_selected(ability_name):
	print("Ability selected:", ability_name)
	battle_manager.player_ability_selected(ability_name)
	ability_button.button_pressed = false

func _on_rest_button_pressed() -> void:
	battle_manager.rest()

func _on_flee_button_pressed() -> void:
	current_quest.fail_quest()
	_quest_finished()

func _on_victory_popup_continue_pressed() -> void:
	battle_manager.get_new_monster()
	battle_manager.start_player_turn()

func _on_player_turn():
	ability_button.disabled = not hero.can_use_abilities()
	item_button.disabled = true
	rest_button.disabled = false
	flee_button.disabled = false

func _on_monster_turn():
	ability_button.disabled = true
	item_button.disabled = true
	rest_button.disabled = true
	flee_button.disabled = true

func _on_quest_completed():
	print("Quest completed!")
	_quest_finished()

func _on_hero_defeated():
	print("Hero defeated!")
	get_tree().change_scene_to_file("res://scenes/ui/screens/defeat_screen.tscn")

func _quest_finished():
	get_tree().change_scene_to_file("res://scenes/ui/screens/quest_finished_screen.tscn")

func _on_pause_button_pressed() -> void:
	pause_popup.popup_centered()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not pause_popup.is_visible():
		_on_pause_button_pressed()
