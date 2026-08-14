extends TestCase

const WINDOW_SCENES: Array[PackedScene] = [
	preload("res://scenes/ui/windows/dialogue_window.tscn"),
	preload("res://scenes/ui/windows/inn_window.tscn"),
	preload("res://scenes/ui/windows/shop_window.tscn"),
	preload("res://scenes/ui/windows/quest_window.tscn"),
	preload("res://scenes/ui/windows/options_window.tscn"),
	preload("res://scenes/ui/windows/load_window.tscn"),
	preload("res://scenes/ui/windows/new_game_window.tscn"),
	preload("res://scenes/ui/windows/reward_window.tscn"),
	preload("res://scenes/ui/windows/death_window.tscn"),
]

const CONVERTED_WINDOW_SCENES: Array[PackedScene] = [
	preload("res://scenes/ui/windows/options_window.tscn"),
	preload("res://scenes/ui/windows/load_window.tscn"),
	preload("res://scenes/ui/windows/new_game_window.tscn"),
	preload("res://scenes/ui/windows/reward_window.tscn"),
	preload("res://scenes/ui/windows/death_window.tscn"),
]

const INN_WINDOW_SCENE := preload(
	"res://scenes/ui/windows/inn_window.tscn"
)
const SHOP_WINDOW_SCENE := preload(
	"res://scenes/ui/windows/shop_window.tscn"
)
const QUEST_WINDOW_SCENE := preload(
	"res://scenes/ui/windows/quest_window.tscn"
)
const OPTIONS_WINDOW_SCENE := preload(
	"res://scenes/ui/windows/options_window.tscn"
)
const LOAD_WINDOW_SCENE := preload(
	"res://scenes/ui/windows/load_window.tscn"
)
const NEW_GAME_WINDOW_SCENE := preload(
	"res://scenes/ui/windows/new_game_window.tscn"
)
const REWARD_WINDOW_SCENE := preload(
	"res://scenes/ui/windows/reward_window.tscn"
)
const DEATH_WINDOW_SCENE := preload(
	"res://scenes/ui/windows/death_window.tscn"
)
const NEW_GAME_SCREEN_SCENE := preload(
	"res://scenes/ui/screens/new_game_screen.tscn"
)
const QUEST_BUTTON_SCENE := preload(
	"res://scenes/ui/components/quest_button.tscn"
)
const GAME_HUD_SCENE := preload("res://scenes/ui/hud/game_hud.tscn")
const QUESTS_PANEL_SCENE := preload(
	"res://scenes/ui/hud/panels/quests_panel.tscn"
)

var _reward_collection_count: int = 0
var _return_to_village_count: int = 0
var _confirmation_cancel_count: int = 0

func run_tests() -> int:
	_begin_test_run()
	var original_navigation_mode := InputManager.menu_navigation_mode
	InputManager._set_menu_navigation_mode(
		InputManager.MenuNavigationMode.FOCUS
	)
	_test_native_windows_are_consolidated()
	_test_converted_windows_start_hidden()
	_test_game_window_lifecycle()
	_test_static_default_focus_targets()
	_test_shop_item_selection_and_weapon_ownership()
	_test_options_window_focus_graph()
	_test_game_hud_reports_options_modal()
	_test_completed_quest_section_collapse()
	_test_load_window_focus_fallbacks()
	_test_load_window_focus_graph()
	_test_new_game_slot_focus_graph()
	_test_nested_confirmation_focus()
	_test_new_game_screen_focus_graph()
	_test_quest_action_focus_route()
	_test_quest_tab_shortcuts_wrap()
	_test_required_modal_cancel_flows()
	_test_quest_reward_focus_recovery_is_connected()
	InputManager._set_menu_navigation_mode(original_navigation_mode)
	return _finish_test_run("Game window consolidation tests")

func _test_native_windows_are_consolidated() -> void:
	for window_scene: PackedScene in WINDOW_SCENES:
		var instance := window_scene.instantiate()
		add_child(instance)
		_expect_true(
			instance is GameWindow,
			"%s uses the shared GameWindow base" % instance.name
		)
		_expect_true(
			not instance is Window,
			"%s no longer uses a native Window root" % instance.name
		)
		if instance is NewGameWindow:
			var overwrite_window := instance.get_node("OverwriteWindow")
			_expect_true(
				overwrite_window is ConfirmationWindow,
				"overwrite confirmation uses a GameWindow overlay"
			)
		instance.free()

func _test_converted_windows_start_hidden() -> void:
	for window_scene: PackedScene in CONVERTED_WINDOW_SCENES:
		var window := _spawn_window(window_scene)
		_expect_true(
			not window.is_open(),
			"%s starts hidden after entering the scene tree" % window.name
		)
		window.free()

func _test_game_window_lifecycle() -> void:
	var parent_context := Control.new()
	var launcher := Button.new()
	parent_context.add_child(launcher)
	add_child(parent_context)
	InputManager.push_menu_focus_context(
		parent_context,
		Callable(self, "_return_control").bind(launcher)
	)
	launcher.grab_focus()

	var window := GameWindow.new()
	var window_button := Button.new()
	window.add_child(window_button)
	window.hide()
	add_child(window)

	window.open()
	_expect_true(window.is_open(), "open shows a GameWindow")
	window_button.grab_focus()
	window.close()
	_expect_true(not window.is_open(), "close hides a GameWindow")
	_expect_equal(
		get_viewport().gui_get_focus_owner(),
		launcher,
		"closing a GameWindow restores its launcher focus"
	)

	window.free()
	launcher.free()
	InputManager.pop_menu_focus_context(parent_context)
	parent_context.free()

func _test_static_default_focus_targets() -> void:
	var inn_window := _spawn_window(INN_WINDOW_SCENE) as InnWindow
	_expect_equal(
		inn_window._get_default_focus_target(),
		inn_window.rest_button,
		"inn windows default to Rest"
	)
	inn_window.free()

	var shop_window := _spawn_window(SHOP_WINDOW_SCENE) as ShopWindow
	for child: Node in shop_window.item_list.get_children():
		child.free()
	_expect_equal(
		shop_window._get_default_focus_target(),
		shop_window.close_button,
		"empty shops fall back to Close"
	)
	shop_window.free()

	var quest_window := _spawn_window(QUEST_WINDOW_SCENE) as QuestWindow
	_expect_equal(
		quest_window._get_default_focus_target(),
		quest_window.available_button,
		"quest windows default to the Available tab"
	)
	quest_window.free()

	var options_window := _spawn_window(
		OPTIONS_WINDOW_SCENE
	) as OptionsWindow
	_expect_equal(
		options_window._get_default_focus_target(),
		options_window.master_volume_slider,
		"options windows default to Master Volume"
	)
	options_window.free()

	var new_game_window := _spawn_window(
		NEW_GAME_WINDOW_SCENE
	) as NewGameWindow
	_expect_equal(
		new_game_window._get_default_focus_target(),
		new_game_window.slot_buttons[0],
		"new-game windows default to the first save slot"
	)
	new_game_window.free()

	var reward_window := _spawn_window(
		REWARD_WINDOW_SCENE
	) as RewardWindow
	_expect_equal(
		reward_window._get_default_focus_target(),
		reward_window.collect_button,
		"reward windows default to Collect"
	)
	reward_window.free()

	var death_window := _spawn_window(
		DEATH_WINDOW_SCENE
	) as DeathWindow
	_expect_equal(
		death_window._get_default_focus_target(),
		death_window.return_button,
		"death windows default to Return to Village"
	)
	death_window.free()

func _test_shop_item_selection_and_weapon_ownership() -> void:
	var shop_window := _spawn_window(SHOP_WINDOW_SCENE) as ShopWindow
	var first_button := shop_window.create_item_button(
		"bronze_mace",
		1
	)
	var second_button := shop_window.create_item_button(
		"iron_longsword",
		1
	)
	shop_window.item_list.add_child(first_button)
	shop_window.item_list.add_child(second_button)
	shop_window._item_buttons.assign([first_button, second_button])

	_expect_true(first_button.toggle_mode, "shop items use toggle buttons")
	_expect_equal(
		first_button.button_group,
		second_button.button_group,
		"shop item toggles share an exclusive selection group"
	)
	var hero := HeroLoader.new_hero(Hero.HeroClass.KNIGHT)
	hero.inventory.gold = 9999
	hero.inventory.weapon_stash.append("iron_longsword")
	var weapon_shop := Shop.new()
	weapon_shop.inventory = {
		"bronze_mace": 1,
		"iron_longsword": 1,
	}
	shop_window.hero = hero
	shop_window.shop = weapon_shop
	shop_window.shop_type = ShopWindow.ShopType.WEAPON
	shop_window.shop_manager.hero = hero
	shop_window.shop_manager.shop = weapon_shop
	shop_window._on_item_pressed("iron_longsword")
	_expect_true(
		second_button.button_pressed,
		"the displayed shop item remains visibly selected"
	)
	_expect_true(
		not first_button.button_pressed,
		"selecting another shop item clears the previous toggle"
	)

	_expect_true(
		shop_window.purchase_button.disabled,
		"owned weapons disable Purchase even when the hero has enough gold"
	)
	_expect_true(
		not shop_window.shop_manager.can_buy_selected(),
		"the shop manager rejects duplicate weapon purchases"
	)
	shop_window.free()

func _test_load_window_focus_fallbacks() -> void:
	var load_window := _spawn_window(LOAD_WINDOW_SCENE) as LoadWindow
	for button: Button in load_window.slot_buttons:
		load_window.setup_empty_slot(button)
	_expect_equal(
		load_window._get_default_focus_target(),
		load_window.back_button,
		"load windows fall back to Back when every slot is empty"
	)

	var filled_slot := load_window.slot_buttons[2]
	load_window.setup_filled_slot(
		filled_slot,
		{
			"hero_name": "Test Hero",
			"level": 3,
			"time": "Test Time",
		}
	)
	_expect_equal(
		load_window._get_default_focus_target(),
		filled_slot,
		"load windows choose the first enabled save slot"
	)

	load_window.open()
	var stranded_delete := load_window.delete_buttons[2]
	stranded_delete.disabled = false
	stranded_delete.grab_focus()
	stranded_delete.disabled = true
	load_window._apply_default_focus()
	_expect_equal(
		get_viewport().gui_get_focus_owner(),
		filled_slot,
		"load windows can repair focus after a delete button is disabled"
	)
	load_window.free()

func _test_options_window_focus_graph() -> void:
	var options_window := _spawn_window(
		OPTIONS_WINDOW_SCENE
	) as OptionsWindow
	var controls: Array[Control] = [
		options_window.master_volume_slider,
		options_window.music_volume_slider,
		options_window.sfx_volume_slider,
		options_window.fullscreen_button,
		options_window.close_button,
	]
	for index: int in controls.size():
		var control: Control = controls[index]
		var top_target: Control = controls[maxi(index - 1, 0)]
		var bottom_target: Control = controls[mini(index + 1, controls.size() - 1)]
		_expect_equal(
			control.focus_neighbor_top,
			control.get_path_to(top_target),
			"options control %d has an explicit upward target" % index
		)
		_expect_equal(
			control.focus_neighbor_bottom,
			control.get_path_to(bottom_target),
			"options control %d has an explicit downward target" % index
		)
	_expect_equal(
		options_window.fullscreen_button.focus_neighbor_bottom,
		options_window.fullscreen_button.get_path_to(options_window.close_button),
		"Fullscreen navigates down to Close instead of the underlying screen"
	)
	_expect_equal(
		options_window.close_button.focus_neighbor_bottom,
		options_window.close_button.get_path_to(options_window.close_button),
		"Close cannot navigate down out of the options modal"
	)
	options_window.free()

func _test_game_hud_reports_options_modal() -> void:
	var game_hud := GAME_HUD_SCENE.instantiate() as GameHUD
	add_child(game_hud)
	game_hud.show_hud(GameHUD.Tab.SYSTEM)
	_expect_true(
		not game_hud.has_open_modal(),
		"the game HUD starts without an open modal"
	)
	game_hud.system_panel.options_window.open()
	_expect_true(
		game_hud.has_open_modal(),
		"the game HUD reports its open Options modal"
	)
	game_hud.system_panel.options_window.close()
	_expect_true(
		not game_hud.has_open_modal(),
		"the game HUD clears modal state when Options closes"
	)
	game_hud.free()

func _test_completed_quest_section_collapse() -> void:
	var quests_panel := QUESTS_PANEL_SCENE.instantiate() as QuestsPanel
	add_child(quests_panel)
	quests_panel._clear_container(quests_panel.active_list)
	quests_panel._clear_container(quests_panel.completed_list)
	quests_panel._active_buttons.clear()
	quests_panel._completed_buttons.clear()
	quests_panel._buttons_by_id.clear()

	var active_quest := Quest.new()
	active_quest.id = 901
	active_quest.title = "Active Test Quest"
	var active_button := QUEST_BUTTON_SCENE.instantiate() as QuestButton
	active_button.setup(active_quest, QuestButton.DisplayState.ACTIVE)
	quests_panel.active_list.add_child(active_button)
	quests_panel._active_buttons.append(active_button)
	quests_panel._buttons_by_id[active_quest.id] = active_button

	var completed_quest := Quest.new()
	completed_quest.id = 902
	completed_quest.title = "Completed Test Quest"
	completed_quest.objectives.append(QuestObjective.new())
	var completed_button := QUEST_BUTTON_SCENE.instantiate() as QuestButton
	completed_button.setup(
		completed_quest,
		QuestButton.DisplayState.COMPLETED
	)
	quests_panel.completed_list.add_child(completed_button)
	quests_panel._completed_buttons.append(completed_button)
	quests_panel._buttons_by_id[completed_quest.id] = completed_button
	_expect_equal(
		completed_button.size_flags_vertical,
		Control.SIZE_FILL,
		"completed quest cards use their content height instead of expanding vertically"
	)
	var objective_label := completed_button.objectives_list.get_child(0) as Label
	_expect_equal(
		objective_label.custom_minimum_size.x,
		completed_button.description_label.custom_minimum_size.x,
		"hidden completed objectives measure at the quest card content width"
	)

	quests_panel._completed_quest_count = 1
	quests_panel._completed_list_expanded = false
	quests_panel.track_button.disabled = false
	quests_panel._sync_completed_section()
	quests_panel._configure_focus_graph()
	_expect_true(
		not quests_panel.completed_list.visible,
		"completed quests start hidden when the section is collapsed"
	)
	_expect_equal(
		active_button.focus_neighbor_bottom,
		active_button.get_path_to(quests_panel.completed_header),
		"collapsed navigation moves from active quests to the completed header"
	)
	_expect_equal(
		quests_panel.completed_header.focus_neighbor_bottom,
		quests_panel.completed_header.get_path_to(quests_panel.track_button),
		"collapsed navigation skips hidden completed quests"
	)

	quests_panel._on_completed_header_toggled(true)
	_expect_true(
		quests_panel.completed_list.visible,
		"toggling the completed header expands the completed list"
	)
	_expect_equal(
		quests_panel.completed_header.focus_neighbor_bottom,
		quests_panel.completed_header.get_path_to(completed_button),
		"expanded navigation enters the completed quest list"
	)
	_expect_equal(
		completed_button.focus_neighbor_bottom,
		completed_button.get_path_to(quests_panel.track_button),
		"expanded completed quests reconnect to the next visible control"
	)

	quests_panel._last_focused_quest_id = completed_quest.id
	quests_panel._on_completed_header_toggled(false)
	_expect_equal(
		quests_panel.get_default_focus_target(),
		active_button,
		"default focus ignores a previously focused hidden completed quest"
	)

	quests_panel._completed_quest_count = 0
	quests_panel._completed_list_expanded = true
	quests_panel._sync_completed_section()
	_expect_true(
		quests_panel.completed_header.disabled,
		"an empty completed section cannot receive stranded focus"
	)
	_expect_true(
		not quests_panel.completed_list.visible,
		"an empty completed section remains hidden"
	)
	quests_panel.free()

func _test_load_window_focus_graph() -> void:
	var load_window := _spawn_window(LOAD_WINDOW_SCENE) as LoadWindow
	for index: int in load_window.slot_buttons.size():
		load_window.setup_empty_slot(load_window.slot_buttons[index])
		load_window.delete_buttons[index].disabled = true

	var filled_index := 2
	var filled_slot := load_window.slot_buttons[filled_index]
	var delete_button := load_window.delete_buttons[filled_index]
	load_window.setup_filled_slot(filled_slot, {})
	delete_button.disabled = false
	load_window._rebuild_focus_graph()

	_expect_equal(
		filled_slot.focus_neighbor_right,
		filled_slot.get_path_to(delete_button),
		"load slots navigate right to their matching Delete action"
	)
	_expect_equal(
		delete_button.focus_neighbor_bottom,
		delete_button.get_path_to(load_window.back_button),
		"the final enabled delete action navigates down to Back"
	)
	load_window.free()

func _test_new_game_slot_focus_graph() -> void:
	var new_game_window := _spawn_window(
		NEW_GAME_WINDOW_SCENE
	) as NewGameWindow
	for index: int in range(1, new_game_window.slot_buttons.size() - 1):
		var button: Button = new_game_window.slot_buttons[index]
		_expect_equal(
			button.focus_neighbor_top,
			button.get_path_to(new_game_window.slot_buttons[index - 1]),
			"new-game middle slot %d navigates to the previous slot" % (index + 1)
		)
		_expect_equal(
			button.focus_neighbor_bottom,
			button.get_path_to(new_game_window.slot_buttons[index + 1]),
			"new-game middle slot %d navigates to the next slot" % (index + 1)
		)
	_expect_equal(
		new_game_window.slot_buttons.back().focus_neighbor_bottom,
		new_game_window.slot_buttons.back().get_path_to(new_game_window.back_button),
		"the final new-game slot navigates down to Back"
	)
	new_game_window.free()

func _test_nested_confirmation_focus() -> void:
	_confirmation_cancel_count = 0
	var new_game_window := _spawn_window(
		NEW_GAME_WINDOW_SCENE
	) as NewGameWindow
	var overwrite_window := new_game_window.overwrite_window
	overwrite_window.cancelled.connect(_on_confirmation_cancelled)

	new_game_window.open()
	new_game_window._apply_default_focus()
	var selected_slot := new_game_window.slot_buttons[0]
	selected_slot.grab_focus()

	overwrite_window.open()
	overwrite_window._apply_default_focus()
	_expect_true(
		new_game_window.has_open_child_window(),
		"new-game slot window recognizes its open confirmation child"
	)
	_expect_equal(
		get_viewport().gui_get_focus_owner(),
		overwrite_window.cancel_button,
		"overwrite confirmation defaults to the safe Cancel action"
	)

	overwrite_window._handle_cancel()
	_expect_equal(
		_confirmation_cancel_count,
		1,
		"cancel input emits the confirmation cancellation signal"
	)
	_expect_equal(
		get_viewport().gui_get_focus_owner(),
		selected_slot,
		"cancelling overwrite restores the selected save slot"
	)
	new_game_window.free()

func _test_new_game_screen_focus_graph() -> void:
	var screen := NEW_GAME_SCREEN_SCENE.instantiate() as NewGameScreen
	add_child(screen)
	_expect_equal(
		screen._hero_previews.size(),
		3,
		"character creation builds all three hero previews"
	)
	var first_preview: HeroPreview = screen._hero_previews[0]
	_expect_equal(
		first_preview.focus_neighbor_bottom,
		first_preview.get_path_to(screen.hero_name),
		"hero previews navigate down to the name field"
	)
	screen.free()

func _test_quest_action_focus_route() -> void:
	var quest_window := _spawn_window(QUEST_WINDOW_SCENE) as QuestWindow
	var quest_button := QUEST_BUTTON_SCENE.instantiate() as QuestButton
	quest_window.quest_list.add_child(quest_button)
	quest_window._quest_buttons.append(quest_button)

	quest_window.action_button.disabled = false
	quest_window._configure_focus_graph()
	_expect_equal(
		quest_button.focus_neighbor_bottom,
		quest_button.get_path_to(quest_window.action_button),
		"a selectable quest navigates down to an enabled Turn In action"
	)

	quest_window.action_button.disabled = true
	quest_window._configure_focus_graph()
	_expect_equal(
		quest_button.focus_neighbor_bottom,
		quest_button.get_path_to(quest_window.close_button),
		"a quest skips a disabled action and navigates to Close"
	)
	quest_window.free()

func _test_quest_tab_shortcuts_wrap() -> void:
	var quest_window := _spawn_window(QUEST_WINDOW_SCENE) as QuestWindow
	quest_window._select_tab(QuestWindow.Tab.AVAILABLE)
	quest_window._switch_relative_tab(-1)
	_expect_equal(
		quest_window._current_tab,
		QuestWindow.Tab.COMPLETED,
		"quest tab-left wraps from Available to Completed"
	)
	_expect_true(
		quest_window.completed_button.button_pressed,
		"relative quest tab switching updates the pressed tab"
	)

	quest_window._switch_relative_tab(1)
	_expect_equal(
		quest_window._current_tab,
		QuestWindow.Tab.AVAILABLE,
		"quest tab-right wraps from Completed to Available"
	)
	quest_window._switch_relative_tab(1)
	_expect_equal(
		quest_window._current_tab,
		QuestWindow.Tab.ACTIVE,
		"quest tab-right advances from Available to Active"
	)
	quest_window.free()

func _test_required_modal_cancel_flows() -> void:
	_reward_collection_count = 0
	var reward_window := _spawn_window(
		REWARD_WINDOW_SCENE
	) as RewardWindow
	reward_window.rewards_collected.connect(_on_rewards_collected)
	reward_window.open()
	reward_window._apply_default_focus()
	_expect_equal(
		get_viewport().gui_get_focus_owner(),
		reward_window.collect_button,
		"reward windows focus Collect when opened"
	)
	reward_window._handle_cancel()
	_expect_equal(
		_reward_collection_count,
		1,
		"reward cancel input continues the reward flow"
	)
	reward_window.free()

	_return_to_village_count = 0
	var death_window := _spawn_window(
		DEATH_WINDOW_SCENE
	) as DeathWindow
	death_window.return_to_village.connect(_on_return_to_village)
	death_window.open()
	death_window._apply_default_focus()
	_expect_equal(
		get_viewport().gui_get_focus_owner(),
		death_window.return_button,
		"death windows focus Return to Village when opened"
	)
	death_window._handle_cancel()
	_expect_equal(
		_return_to_village_count,
		1,
		"death cancel input continues the return-to-village flow"
	)
	death_window.free()

func _test_quest_reward_focus_recovery_is_connected() -> void:
	var quest_window := _spawn_window(QUEST_WINDOW_SCENE) as QuestWindow
	_expect_true(
		quest_window.reward_window.rewards_collected.is_connected(
			quest_window._on_reward_window_collected
		),
		"quest rewards connect a deterministic post-reward focus target"
	)
	quest_window.free()

func _spawn_window(scene: PackedScene) -> GameWindow:
	var window := scene.instantiate() as GameWindow
	add_child(window)
	return window

func _return_control(control: Control) -> Control:
	return control

func _on_rewards_collected() -> void:
	_reward_collection_count += 1

func _on_return_to_village() -> void:
	_return_to_village_count += 1

func _on_confirmation_cancelled() -> void:
	_confirmation_cancel_count += 1
