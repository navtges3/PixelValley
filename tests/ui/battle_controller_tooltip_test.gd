extends TestCase

const BATTLE_SCREEN_SCENE := preload("res://scenes/ui/screens/battle_screen.tscn")

func run_tests() -> int:
	_begin_test_run()
	_test_focus_and_hover_tooltip()
	return _finish_test_run("Battle ability tooltip tests")

func _test_focus_and_hover_tooltip() -> void:
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
		screen.ability_tooltip.visible,
		"controller focus shows the combat ability tooltip"
	)
	_expect_equal(
		screen.ability_tooltip_label.text,
		button.ability_tooltip_text,
		"focused ability shows its details in the shared tooltip"
	)
	_expect_true(
		button.tooltip_text.is_empty(),
		"ability disables the duplicate native mouse tooltip"
	)
	screen.item_button.grab_focus()
	_expect_true(
		not screen.ability_tooltip.visible,
		"moving focus away from the ability hides the controller tooltip"
	)

	InputManager._set_input_method(InputManager.InputMethod.KEYBOARD_MOUSE)
	button.mouse_entered.emit()
	_expect_true(
		screen.ability_tooltip.visible,
		"mouse hover shows the shared ability tooltip"
	)
	button.mouse_exited.emit()
	_expect_true(not screen.ability_tooltip.visible, "ending mouse hover hides the tooltip")
	screen._reset_action_submenu()
	_expect_true(
		not screen.ability_tooltip.visible,
		"closing the ability submenu clears the controller tooltip"
	)

	screen.free()
	InputManager._set_input_method(original_input_method)
