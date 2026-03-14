extends Control

@onready var battle_manager = $BattleManager

# Top Bar
@onready var quest_bar = $TopBar/QuestProgressBar
@onready var victory_popup = $BattleVictoryPopup
@onready var monster_health_bar: ProgressBar = $TopBar/VBoxContainer/MonsterHealthBar
@onready var monster_health_bar_label: Label = $TopBar/VBoxContainer/MonsterHealthBar/MonsterHealthBarLabel
@onready var monster_label: Label = $TopBar/VBoxContainer/MonsterLabel

# Action Area
@onready var hero_info: HeroInfo = $ActionArea/HeroInfo
@onready var ability_button = $ActionArea/LeftPanel/AbilityButton
@onready var item_button = $ActionArea/LeftPanel/ItemButton
@onready var meditate_button = $ActionArea/LeftPanel/MeditateButton
@onready var flee_button = $ActionArea/LeftPanel/FleeButton

@onready var option_list = $ActionArea/MiddlePanel/OptionList

var AbilityButton := preload("res://scenes/ui/components/ability_button.tscn")
var ItemButton := preload("res://scenes/ui/components/item_button.tscn")
const BATTLE_CHARACTER = preload("uid://bsh4xy5omgwej")
const GOBLIN_SPRITE_FRAMES = preload("uid://4ywebwliybf7")
const KNIGHT_SPRITE_FRAMES = preload("uid://cxd5elo40h8pv")

var battle_config: BattleConfig
var hero_visual
var monster_visual

func _ready() -> void:
	quest_bar.quest = battle_config.quest
	quest_bar.update_quest()
	_empty_option_list()
	_spawn_hero()

	battle_manager.setup_battle(battle_config)

func setup(config: BattleConfig) -> void:
	battle_config = config

func _spawn_hero() -> void:
	hero_info.hero = battle_config.hero
	hero_visual = BATTLE_CHARACTER.instantiate()
	$HeroSlot.add_child(hero_visual)
	hero_visual.set_frames(battle_config.hero.battle_visual.frames)
	hero_visual.scale.x = 5
	hero_visual.scale.y = 5

func _on_hero_updated(_hero_ref: Hero) -> void:
	hero_info.refresh()

func _on_hero_attacking() -> void:
	hero_visual.play_attack()
	await hero_visual.animation_done

func _on_hero_hurt() -> void:
	hero_visual.play_hurt()

func _on_new_monster(monster_ref: Monster) -> void:
	monster_label.text = monster_ref.name
	_on_monster_updated(monster_ref)
	_spawn_monster(monster_ref)

func _spawn_monster(monster_ref: Monster) -> void:
	for child in $MonsterSlot.get_children():
		child.queue_free()
	monster_visual = BATTLE_CHARACTER.instantiate()
	$MonsterSlot.add_child(monster_visual)
	monster_visual.set_frames(monster_ref.battle_visual.frames)
	monster_visual.scale.x = -5
	monster_visual.scale.y = 5

func _on_monster_updated(monster_ref: Monster) -> void:
	var value = monster_ref.stat_block.current_hp
	var max_value = monster_ref.stat_block.max_hp
	monster_health_bar.max_value = max_value
	monster_health_bar.value = value
	monster_health_bar_label.text = "%d / %d" % [value, max_value]

func _on_monster_attacking() -> void:
	monster_visual.play_attack()
	await monster_visual.animation_done

func _on_monster_hurt() -> void:
	monster_visual.play_hurt()

func _on_monster_slain(monster_name: String) -> void:
	print("%s was slain!" % monster_name)
	monster_visual.play_death()
	await monster_visual.animation_done
	quest_bar.update_bar()
	victory_popup.popup_centered()

func _on_battle_log_updated(msg: String) -> void:
	$ActionArea/BattleLog.append_text(msg)

func _on_ability_button_toggled(button_pressed: bool):
	if button_pressed:
		item_button.button_pressed = false
		option_list.visible = true
		_empty_option_list()
		for ability: Ability in battle_manager.get_hero_abilities():
			var btn = _create_ability_button(ability)
			option_list.add_child(btn)
	else:
		option_list.visible = false

func _on_item_button_toggled(button_pressed: bool):
	if button_pressed:
		ability_button.button_pressed = false
		option_list.visible = true
		_empty_option_list()
		for item_stack: ItemStack in battle_manager.get_hero_items():
			var btn = _create_item_button(item_stack)
			option_list.add_child(btn)
	else:
		option_list.visible = false

func _on_meditate_button_pressed() -> void:
	battle_manager.meditate()
	option_list.visible = false
	ability_button.button_pressed = false
	item_button.button_pressed = false

func _on_flee_button_pressed() -> void:
	if battle_manager.is_test_battle:
		ScreenManager.go_to_screen(ScreenManager.ScreenName.TEST)
	else:
		ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE)

func _on_player_turn():
	ability_button.disabled = false
	item_button.disabled = battle_manager.get_hero_items().is_empty()
	if battle_manager.hero.rest_cooldown > 0:
		meditate_button.disabled = true
		meditate_button.text = "Cooldown: %d" % battle_manager.hero.rest_cooldown
	else:
		meditate_button.disabled = false
		meditate_button.text = "Meditate"
	flee_button.disabled = false

func _on_monster_turn():
	ability_button.disabled = true
	item_button.disabled = true
	meditate_button.disabled = true
	flee_button.disabled = true

func _on_quest_completed():
	print("Quest completed!")
	if battle_config.is_test_battle:
		ScreenManager.go_to_screen(ScreenManager.ScreenName.TEST)
	elif battle_manager.current_quest.id == GameState.quest_manager.LAST_QUEST_ID:
		ScreenManager.go_to_screen(ScreenManager.ScreenName.VICTORY)
	else:
		ScreenManager.go_to_screen(ScreenManager.ScreenName.QUEST_FINISHED)

func _on_hero_defeated():
	print("Hero defeated!")
	ScreenManager.go_to_screen(ScreenManager.ScreenName.DEFEAT)

func _on_victory_popup_continue_pressed() -> void:
	battle_manager.get_new_monster()
	battle_manager.start_player_turn()

func _on_victory_popup_retreat_pressed() -> void:
	if battle_config.is_test_battle:
		ScreenManager.go_to_screen(ScreenManager.ScreenName.TEST)
	else:
		ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE)

func _on_ability_button_pressed(ability: Ability) -> void:
	print("Ability pressed: ", ability.name)
	battle_manager.player_ability_selected(ability)
	ability_button.button_pressed = false

func _create_ability_button(ability: Ability) -> Button:
	var button := AbilityButton.instantiate()
	button.ability = ability
	button.user_energy = battle_manager.hero.stat_block.current_nrg
	button.connect("ability_pressed", Callable(self, "_on_ability_button_pressed"))
	return button

func _on_item_button_pressed(item_stack: ItemStack) -> void:
	print("Item pressed: ", item_stack.item.name)
	battle_manager.player_item_selected(item_stack)
	item_button.button_pressed = false

func _create_item_button(item_stack: ItemStack) -> Button:
	var button := ItemButton.instantiate()
	button.item_stack = item_stack
	button.connect("item_pressed", Callable(self, "_on_item_button_pressed"))
	return button

func _empty_option_list() -> void:
	for child in option_list.get_children():
			child.queue_free()
