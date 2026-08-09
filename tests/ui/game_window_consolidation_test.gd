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

var _reward_collection_count: int = 0
var _return_to_village_count: int = 0
var _confirmation_cancel_count: int = 0

func run_tests() -> int:
	_begin_test_run()
	_test_native_windows_are_consolidated()
	_test_converted_windows_start_hidden()
	_test_game_window_lifecycle()
	_test_static_default_focus_targets()
	_test_load_window_focus_fallbacks()
	_test_nested_confirmation_focus()
	_test_required_modal_cancel_flows()
	_test_quest_reward_focus_recovery_is_connected()
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
	var launcher := Button.new()
	add_child(launcher)
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
	window._restore_previous_focus()
	_expect_true(not window.is_open(), "close hides a GameWindow")
	_expect_equal(
		get_viewport().gui_get_focus_owner(),
		launcher,
		"closing a GameWindow restores its launcher focus"
	)

	window.free()
	launcher.free()

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
	_expect_equal(
		get_viewport().gui_get_focus_owner(),
		overwrite_window.cancel_button,
		"overwrite confirmation defaults to the safe Cancel action"
	)

	overwrite_window._handle_cancel()
	overwrite_window._restore_previous_focus()
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

func _on_rewards_collected() -> void:
	_reward_collection_count += 1

func _on_return_to_village() -> void:
	_return_to_village_count += 1

func _on_confirmation_cancelled() -> void:
	_confirmation_cancel_count += 1
