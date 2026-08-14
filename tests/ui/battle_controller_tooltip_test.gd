extends TestCase

const BATTLE_SCREEN_SCENE := preload("res://scenes/ui/screens/battle_screen.tscn")

func run_tests() -> int:
	_begin_test_run()
	_test_focus_and_hover_tooltip()
	_test_item_focus_and_hover_tooltip()
	_test_meditate_focus_and_hover_tooltip()
	return _finish_test_run("Battle option tooltip tests")

func _test_focus_and_hover_tooltip() -> void:
	var original_input_method := InputManager.active_input_method
	var original_navigation_mode := InputManager.menu_navigation_mode
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
	InputManager._set_menu_navigation_mode(InputManager.MenuNavigationMode.FOCUS)
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
	InputManager._set_menu_navigation_mode(InputManager.MenuNavigationMode.POINTER)
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
	InputManager._set_menu_navigation_mode(original_navigation_mode)

func _test_item_focus_and_hover_tooltip() -> void:
	var original_input_method := InputManager.active_input_method
	var original_navigation_mode := InputManager.menu_navigation_mode
	var screen := BATTLE_SCREEN_SCENE.instantiate() as BattleScreen
	add_child(screen)

	var button := screen._create_item_button("lesser_healing_potion", 2)
	screen.option_list.add_child(button)
	screen.option_list.visible = true
	screen.item_button.set_pressed_no_signal(true)

	InputManager._set_input_method(InputManager.InputMethod.CONTROLLER)
	InputManager._set_menu_navigation_mode(InputManager.MenuNavigationMode.FOCUS)
	button.grab_focus()
	_expect_true(
		screen.ability_tooltip.visible,
		"controller focus shows the potion tooltip"
	)
	_expect_equal(
		screen.ability_tooltip_label.text,
		button.item_tooltip_text,
		"focused potion shows its details in the shared tooltip"
	)
	_expect_true(
		button.tooltip_text.is_empty(),
		"potion disables the duplicate native mouse tooltip"
	)

	InputManager._set_input_method(InputManager.InputMethod.KEYBOARD_MOUSE)
	InputManager._set_menu_navigation_mode(InputManager.MenuNavigationMode.POINTER)
	button.mouse_entered.emit()
	_expect_true(
		screen.ability_tooltip.visible,
		"mouse hover shows the potion tooltip"
	)
	button.mouse_exited.emit()
	_expect_true(
		not screen.ability_tooltip.visible,
		"ending potion mouse hover hides the tooltip"
	)

	screen.free()
	InputManager._set_input_method(original_input_method)
	InputManager._set_menu_navigation_mode(original_navigation_mode)

func _test_meditate_focus_and_hover_tooltip() -> void:
	var original_input_method := InputManager.active_input_method
	var original_navigation_mode := InputManager.menu_navigation_mode
	var screen := BATTLE_SCREEN_SCENE.instantiate() as BattleScreen
	add_child(screen)

	InputManager._set_input_method(InputManager.InputMethod.CONTROLLER)
	InputManager._set_menu_navigation_mode(InputManager.MenuNavigationMode.FOCUS)
	screen.meditate_button.grab_focus()
	_expect_true(
		screen.ability_tooltip.visible,
		"controller focus shows the meditate tooltip"
	)
	_expect_equal(
		screen.ability_tooltip_label.text,
		BattleScreen.MEDITATE_TOOLTIP_TEXT,
		"focused meditate action shows its details in the shared tooltip"
	)
	_expect_true(
		screen.meditate_button.tooltip_text.is_empty(),
		"meditate disables the duplicate native mouse tooltip"
	)

	InputManager._set_input_method(InputManager.InputMethod.KEYBOARD_MOUSE)
	InputManager._set_menu_navigation_mode(InputManager.MenuNavigationMode.POINTER)
	screen.meditate_button.mouse_entered.emit()
	_expect_true(
		screen.ability_tooltip.visible,
		"mouse hover shows the meditate tooltip"
	)
	screen.meditate_button.mouse_exited.emit()
	_expect_true(
		not screen.ability_tooltip.visible,
		"ending meditate mouse hover hides the tooltip"
	)

	screen.free()
	InputManager._set_input_method(original_input_method)
	InputManager._set_menu_navigation_mode(original_navigation_mode)
