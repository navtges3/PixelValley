extends TestCase

const BATTLE_SCREEN_SCENE := preload("res://scenes/ui/screens/battle_screen.tscn")

func run_tests() -> int:
	_begin_test_run()
	_test_controller_focus_tooltip()
	return _finish_test_run("Battle controller tooltip tests")

func _test_controller_focus_tooltip() -> void:
	var original_input_method := InputManager.active_input_method
	var screen := BATTLE_SCREEN_SCENE.instantiate() as BattleScreen
	add_child(screen)

	var hero := Hero.new()
	hero.current_nrg = 10
	screen.battle_manager.hero = hero

	var ability := Ability.new()
	ability.name = "Test Strike"
	ability.energy_cost = 3
	ability.cooldown = 2
	var button := screen._create_ability_button(ability)
	screen.option_list.add_child(button)
	screen.option_list.visible = true
	screen.ability_button.set_pressed_no_signal(true)

	InputManager._set_input_method(InputManager.InputMethod.CONTROLLER)
	button.grab_focus()
	_expect_true(
		screen.controller_ability_tooltip.visible,
		"controller focus shows the combat ability tooltip"
	)
	_expect_equal(
		screen.controller_ability_tooltip_label.text,
		button.tooltip_text,
		"controller tooltip reuses the native mouse tooltip text"
	)
	_expect_true(
		not button.tooltip_text.is_empty(),
		"ability keeps its native tooltip text for mouse hover"
	)
	screen.item_button.grab_focus()
	_expect_true(
		not screen.controller_ability_tooltip.visible,
		"moving focus away from the ability hides the controller tooltip"
	)
	button.grab_focus()

	InputManager._set_input_method(InputManager.InputMethod.KEYBOARD_MOUSE)
	_expect_true(
		not screen.controller_ability_tooltip.visible,
		"switching to keyboard and mouse hides the controller tooltip"
	)

	InputManager._set_input_method(InputManager.InputMethod.CONTROLLER)
	_expect_true(
		screen.controller_ability_tooltip.visible,
		"switching back to controller restores the focused ability tooltip"
	)
	screen._reset_action_submenu()
	_expect_true(
		not screen.controller_ability_tooltip.visible,
		"closing the ability submenu clears the controller tooltip"
	)

	screen.free()
	InputManager._set_input_method(original_input_method)
