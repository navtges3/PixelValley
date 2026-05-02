extends Control

const ABILITY_BUTTON = preload("res://scenes/ui/components/ability_button.tscn")
const ITEM_BUTTON = preload("res://scenes/ui/components/item_button.tscn")
const BATTLE_CHARACTER = preload("res://scenes/ui/components/battle_character.tscn")

@onready var battle_manager = $BattleManager

@onready var battle_log: RichTextLabel = $MarginContainer/BattleLog

# Monster Info
@onready var monster_health_bar: ProgressBar = $MarginContainer/VBoxContainer/MonsterHealthBar
@onready var monster_health_bar_label: Label = $MarginContainer/VBoxContainer/MonsterHealthBar/MonsterHealthBarLabel
@onready var monster_label: Label = $MarginContainer/VBoxContainer/MonsterLabel

# Action Area
@onready var hero_info: HeroInfo = $MarginContainer/ActionPanel/ActionArea/HeroInfo
@onready var ability_button: Button = $MarginContainer/ActionPanel/ActionArea/LeftPanel/AbilityButton
@onready var item_button: Button = $MarginContainer/ActionPanel/ActionArea/LeftPanel/ItemButton
@onready var meditate_button: Button = $MarginContainer/ActionPanel/ActionArea/LeftPanel/MeditateButton
@onready var flee_button: Button = $MarginContainer/ActionPanel/ActionArea/LeftPanel/FleeButton
@onready var option_list: VBoxContainer = $MarginContainer/ActionPanel/ActionArea/MiddlePanel/OptionList

var hero_visual: BattleCharacter
var monster_visual: BattleCharacter
var battle_config: Dictionary = {}

func _ready() -> void:
	_empty_option_list()

func setup(config: Dictionary) -> void:
	battle_config = config
	_spawn_hero()
	battle_manager.setup_battle(config)

# --- Hero ---
func _spawn_hero() -> void:
	hero_info.hero = battle_config.hero
	hero_visual = BATTLE_CHARACTER.instantiate()
	$HeroSlot.add_child(hero_visual)
	hero_visual.apply_visual(battle_config.hero.battle_visual)

func _on_hero_updated(_hero_ref: Hero) -> void:
	hero_info.refresh()

func _on_hero_attacking() -> void:
	hero_visual.play_attack()
	await hero_visual.animation_done

func _on_hero_hurt() -> void:
	hero_visual.play_hurt()

# --- Monster ---
func _on_new_monster(monster_ref: Monster) -> void:
	monster_label.text = monster_ref.name
	_on_monster_updated(monster_ref)
	_spawn_monster(monster_ref)

func _spawn_monster(monster_ref: Monster) -> void:
	for child in $MonsterSlot.get_children():
		child.queue_free()
	monster_visual = BATTLE_CHARACTER.instantiate()
	$MonsterSlot.add_child(monster_visual)
	monster_visual.apply_visual(monster_ref.battle_visual, true)

func _on_monster_updated(monster_ref: Monster) -> void:
	var value = monster_ref.current_hp
	var max_value = monster_ref.max_hp
	monster_health_bar.max_value = max_value
	monster_health_bar.value = value
	monster_health_bar_label.text = "%d / %d" % [value, max_value]

func _on_monster_attacking() -> void:
	monster_visual.play_attack()
	await monster_visual.animation_done

func _on_monster_hurt() -> void:
	monster_visual.play_hurt()

# --- Battle Log ---
func _on_battle_log_updated(msg: String) -> void:
	battle_log.append_text(msg)

# --- Action Buttons ---
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
		for item_id in battle_manager.get_hero_items():
			var count: int = battle_manager.get_hero_items()[item_id]
			var btn = _create_item_button(item_id, count)
			option_list.add_child(btn)
	else:
		option_list.visible = false

func _on_meditate_button_pressed() -> void:
	battle_manager.meditate()
	option_list.visible = false
	ability_button.button_pressed = false
	item_button.button_pressed = false

func _on_flee_button_pressed() -> void:
	battle_manager.player_fled()
	ScreenManager.go_back()

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

# --- End-of-battle ---
func _on_battle_won() -> void:
	ScreenManager.go_back()

func _on_hero_defeated():
	GameState.hero.rest()
	ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE, "village")

# --- Button Factories ---
func _on_ability_button_pressed(ability: Ability) -> void:
	print("Ability pressed: ", ability.name)
	battle_manager.player_ability_selected(ability)
	ability_button.button_pressed = false

func _create_ability_button(ability: Ability) -> Button:
	var button := ABILITY_BUTTON.instantiate()
	button.ability = ability
	button.user_energy = battle_manager.hero.current_nrg
	button.connect("ability_pressed", Callable(self, "_on_ability_button_pressed"))
	return button

func _on_item_button_pressed(item_id: String) -> void:
	battle_manager.player_item_selected(item_id)
	item_button.button_pressed = false

func _create_item_button(item_id: String, count: int) -> Button:
	var button := ITEM_BUTTON.instantiate()
	button.item_id = item_id
	button.count = count
	button.connect("item_pressed", Callable(self, "_on_item_button_pressed"))
	return button

func _empty_option_list() -> void:
	for child in option_list.get_children():
			child.queue_free()
