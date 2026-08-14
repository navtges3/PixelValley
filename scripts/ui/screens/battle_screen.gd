extends Control
class_name BattleScreen

const ABILITY_BUTTON = preload("res://scenes/ui/components/ability_button.tscn")
const ITEM_BUTTON = preload("res://scenes/ui/components/item_button.tscn")
const BATTLE_CHARACTER = preload("res://scenes/ui/components/battle_character.tscn")
const MEDITATE_TOOLTIP_TEXT := "Restore health and energy."

@onready var battle_manager: BattleManager = $BattleManager

@onready var reward_window: RewardWindow = $RewardWindow
@onready var death_window: DeathWindow = $DeathWindow
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
@onready var tooltip_panel: PanelContainer = $MarginContainer/TooltipPanel
@onready var tooltip_label: Label = $MarginContainer/TooltipPanel/TooltipLabel

var hero_visual: BattleCharacter
var monster_visual: BattleCharacter
var battle_config: Dictionary = {}

var _primary_action_buttons: Array[Button] = []
var _focused_tooltip_button: Button
var _hovered_tooltip_button: Button

func _ready() -> void:
	_primary_action_buttons = [
		ability_button,
		item_button,
		meditate_button,
		flee_button,
	]
	meditate_button.focus_entered.connect(_on_option_focus_entered.bind(meditate_button))
	meditate_button.focus_exited.connect(_on_option_focus_exited.bind(meditate_button))
	meditate_button.mouse_entered.connect(_on_option_mouse_entered.bind(meditate_button))
	meditate_button.mouse_exited.connect(_on_option_mouse_exited.bind(meditate_button))
	_empty_option_list()
	InputManager.menu_navigation_mode_changed.connect(
		_on_menu_navigation_mode_changed
	)
	InputManager.push_menu_focus_context(
		self,
		Callable(self, "_get_default_focus_target")
	)

func _get_default_focus_target() -> Control:
	if _is_action_submenu_open():
		for child: Node in option_list.get_children():
			var option := child as Control
			if _can_focus_battle_control(option):
				return option
	for button: Button in _primary_action_buttons:
		if _can_focus_battle_control(button):
			return button
	return null

func _can_focus_battle_control(control: Control) -> bool:
	return (
		is_instance_valid(control)
		and not control.is_queued_for_deletion()
		and control.is_visible_in_tree()
		and control.focus_mode != Control.FOCUS_NONE
		and not (control is BaseButton and (control as BaseButton).disabled)
	)

func setup(config: Dictionary) -> void:
	battle_config = config
	_spawn_hero()
	battle_manager.setup_battle(config)
	_refresh_hero_effect_icons()

# --- Effect Icons ---
func _on_effect_lifecycle_changed(event: EffectLifecycleEvent) -> void:
	if event.target == battle_manager.hero:
		_refresh_hero_effect_icons()
	elif event.target == battle_manager.monster:
		_refresh_monster_effect_icons()

func _refresh_hero_effect_icons() -> void:
	if not is_instance_valid(hero_visual):
		return
	var effects := EffectManager.get_active_effects(battle_manager.hero)
	hero_visual.set_effects(effects)

func _refresh_monster_effect_icons() -> void:
	if not is_instance_valid(monster_visual):
		return
	var effects := EffectManager.get_active_effects(battle_manager.monster)
	monster_visual.set_effects(effects)

# --- Hero ---
func _spawn_hero() -> void:
	hero_info.hero = battle_config.hero
	hero_visual = BATTLE_CHARACTER.instantiate()
	$HeroSlot.add_child(hero_visual)
	hero_visual.apply_visual(battle_config.hero)
	_refresh_hero_effect_icons()
	hero_visual.configure_vfx(battle_config.hero.hero_class)
	var weapon: Weapon = battle_config.hero.inventory.equipped_weapon
	if weapon and weapon.sprite:
		hero_visual.equip_weapon(weapon.sprite, weapon.sprite_offset, weapon.tip_offset)
	ability_button.text = weapon.name

func _on_hero_updated(_hero_ref: Hero) -> void:
	hero_info.refresh()

func _on_hero_attacking() -> void:
	hero_visual.play_attack()
	AudioManager.play_sfx_by_id("sword_swing", 1.0, randf_range(0.9, 1.1))
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
	monster_visual.apply_visual(monster_ref, true)
	_refresh_monster_effect_icons()

func _on_monster_updated(monster_ref: Monster) -> void:
	var value: int = monster_ref.current_hp
	var max_value: int = monster_ref.max_hp
	monster_health_bar.max_value = max_value
	monster_health_bar.value = value
	monster_health_bar_label.text = "%d / %d" % [value, max_value]
	_set_bar_color(monster_health_bar, HudBarStyle.hp_color(value, max_value))

func _set_bar_color(bar: ProgressBar, color: Color) -> void:
	HudBarStyle.apply(bar, color)

func _on_monster_attacking() -> void:
	monster_visual.play_attack()
	AudioManager.play_sfx_by_id("sword_swing", 1.0, randf_range(0.9, 1.1))
	await monster_visual.animation_done

func _on_monster_hurt() -> void:
	monster_visual.play_hurt()

# --- Battle Log ---
func _on_battle_log_updated(msg: String) -> void:
	battle_log.append_text(msg)

# --- Action Buttons ---
func _focus_primary_action() -> void:
	for button: Button in _primary_action_buttons:
		if button.disabled or not button.is_visible_in_tree():
			continue
		InputManager.focus_menu_control(button)
		return

func _focus_first_usable_option(fallback: Button) -> void:
	for child: Node in option_list.get_children():
		if child.is_queued_for_deletion():
			continue
		var button := child as Button
		if button == null or button.disabled:
			continue
		if not button.is_visible_in_tree():
			continue
		InputManager.focus_menu_control(button)
		return
	InputManager.focus_menu_control(fallback)

func _on_ability_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		item_button.button_pressed = false
		option_list.visible = true
		_empty_option_list()
		for ability: Ability in battle_manager.get_hero_abilities():
			var btn := _create_ability_button(ability)
			option_list.add_child(btn)
		_focus_first_usable_option.call_deferred(ability_button)
	else:
		_clear_tooltip()
		option_list.visible = false

func _on_item_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		ability_button.button_pressed = false
		option_list.visible = true
		_empty_option_list()
		for item_id in battle_manager.get_hero_items():
			var count: int = battle_manager.get_hero_items()[item_id]
			var btn := _create_item_button(item_id, count)
			option_list.add_child(btn)
		_focus_first_usable_option.call_deferred(item_button)
	else:
		_clear_tooltip()
		option_list.visible = false

func _on_meditate_button_pressed() -> void:
	_clear_tooltip()
	battle_manager.meditate()
	option_list.visible = false
	ability_button.button_pressed = false
	item_button.button_pressed = false

func _on_flee_button_pressed() -> void:
	battle_manager.player_fled()
	ScreenManager.go_back()

func _on_player_turn() -> void:
	ability_button.disabled = false
	item_button.disabled = battle_manager.get_hero_items().is_empty()
	if battle_manager.hero.rest_cooldown > 0:
		meditate_button.disabled = true
		meditate_button.text = "Cooldown: %d" % battle_manager.hero.rest_cooldown
	else:
		meditate_button.disabled = false
		meditate_button.text = "Meditate"
	flee_button.disabled = false
	_reset_action_submenu()
	_focus_primary_action.call_deferred()

func _on_monster_turn() -> void:
	_clear_tooltip()
	ability_button.disabled = true
	item_button.disabled = true
	meditate_button.disabled = true
	flee_button.disabled = true

# --- End-of-battle ---
func _on_battle_won(entries: Array) -> void:
	reward_window.show_rewards("Victory!", entries)
	AudioManager.play_sfx_by_id("levelup")

func _on_rewards_collected() -> void:
	ScreenManager.go_back()

func _on_hero_defeated() -> void:
	GameState.pre_combat_position = Vector2.ZERO
	death_window.open()

func _on_death_window_dismissed() -> void:
	GameState.hero.rest()
	ScreenManager.go_to_screen(ScreenManager.ScreenName.VILLAGE, InnInterior.ENTRANCE_ID)

# --- Button Factories ---
func _on_ability_button_pressed(ability: Ability) -> void:
	_clear_tooltip()
	battle_manager.player_ability_selected(ability)
	ability_button.button_pressed = false

func _create_ability_button(ability: Ability) -> AbilityButton:
	var button := ABILITY_BUTTON.instantiate() as AbilityButton
	button.ability = ability
	button.user_energy = battle_manager.hero.current_nrg
	button.ability_pressed.connect(_on_ability_button_pressed)
	button.focus_entered.connect(_on_ability_option_focus_entered.bind(button))
	button.focus_exited.connect(_on_ability_option_focus_exited.bind(button))
	button.mouse_entered.connect(_on_ability_option_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_ability_option_mouse_exited.bind(button))
	return button

func _on_item_button_pressed(item_id: String) -> void:
	_clear_tooltip()
	battle_manager.player_item_selected(item_id)
	item_button.button_pressed = false

func _create_item_button(item_id: String, count: int) -> ItemButton:
	var button := ITEM_BUTTON.instantiate() as ItemButton
	button.item_id = item_id
	button.count = count
	button.item_pressed.connect(_on_item_button_pressed)
	button.focus_entered.connect(_on_option_focus_entered.bind(button))
	button.focus_exited.connect(_on_option_focus_exited.bind(button))
	button.mouse_entered.connect(_on_option_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_option_mouse_exited.bind(button))
	return button

func _empty_option_list() -> void:
	_clear_tooltip()
	for child in option_list.get_children():
		child.queue_free()

func _on_ability_option_focus_entered(button: AbilityButton) -> void:
	_on_option_focus_entered(button)

func _on_ability_option_focus_exited(button: AbilityButton) -> void:
	_on_option_focus_exited(button)

func _on_ability_option_mouse_entered(button: AbilityButton) -> void:
	_on_option_mouse_entered(button)

func _on_ability_option_mouse_exited(button: AbilityButton) -> void:
	_on_option_mouse_exited(button)

func _on_option_focus_entered(button: Button) -> void:
	_focused_tooltip_button = button
	_refresh_tooltip()

func _on_option_focus_exited(button: Button) -> void:
	if _focused_tooltip_button == button:
		_focused_tooltip_button = null
	_refresh_tooltip()

func _on_option_mouse_entered(button: Button) -> void:
	_hovered_tooltip_button = button
	_refresh_tooltip()

func _on_option_mouse_exited(button: Button) -> void:
	if _hovered_tooltip_button == button:
		_hovered_tooltip_button = null
	_refresh_tooltip()

func _refresh_tooltip() -> void:
	var source_button: Button = null
	if (
		InputManager.menu_navigation_mode == InputManager.MenuNavigationMode.POINTER
		and is_instance_valid(_hovered_tooltip_button)
	):
		source_button = _hovered_tooltip_button
	elif (
		InputManager.menu_navigation_mode == InputManager.MenuNavigationMode.FOCUS
		and is_instance_valid(_focused_tooltip_button)
		and _focused_tooltip_button.has_focus()
	):
		source_button = _focused_tooltip_button
	var should_show := (
		is_instance_valid(source_button)
		and (
			source_button == meditate_button
			or (_is_action_submenu_open() and option_list.is_visible_in_tree())
		)
	)
	tooltip_panel.visible = should_show
	tooltip_label.text = _get_option_tooltip_text(source_button) if should_show else ""

func _get_option_tooltip_text(button: Button) -> String:
	if button is AbilityButton:
		return (button as AbilityButton).ability_tooltip_text
	if button is ItemButton:
		return (button as ItemButton).item_tooltip_text
	if button == meditate_button:
		return MEDITATE_TOOLTIP_TEXT
	return ""

func _clear_tooltip() -> void:
	_focused_tooltip_button = null
	_hovered_tooltip_button = null
	tooltip_panel.visible = false
	tooltip_label.text = ""

func _on_menu_navigation_mode_changed(
	_mode: InputManager.MenuNavigationMode
) -> void:
	_refresh_tooltip()

func _is_action_submenu_open() -> bool:
	return ability_button.button_pressed or item_button.button_pressed

func _reset_action_submenu() -> void:
	ability_button.set_pressed_no_signal(false)
	item_button.set_pressed_no_signal(false)
	option_list.visible = false
	_empty_option_list()

func _close_action_submenu() -> void:
	var return_target: Button = ability_button if ability_button.button_pressed else item_button
	_reset_action_submenu()
	_restore_primary_focus.call_deferred(return_target)

func _restore_primary_focus(preferred: Button) -> void:
	if is_instance_valid(preferred) and preferred.is_visible_in_tree() and not preferred.disabled:
		InputManager.focus_menu_control(preferred)
		return
	_focus_primary_action()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not event.is_action_pressed(&"ui_cancel"):
		return
	if not _is_action_submenu_open():
		return
	_close_action_submenu()
	get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if InputManager.menu_navigation_mode_changed.is_connected(
		_on_menu_navigation_mode_changed
	):
		InputManager.menu_navigation_mode_changed.disconnect(
			_on_menu_navigation_mode_changed
		)
	InputManager.pop_menu_focus_context(self)
