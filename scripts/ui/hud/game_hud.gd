extends CanvasLayer
class_name GameHUD

enum Tab {
	PARTY,
	INVENTORY,
	QUESTS,
	SYSTEM,
}

signal hud_closed

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Panel
@onready var content_area: Control = $Panel/MarginContainer/VBox/MarginContainer/ContentArea

@onready var party_button: Button = $Panel/MarginContainer/VBox/TabBar/PartyButton
@onready var inventory_button: Button = $Panel/MarginContainer/VBox/TabBar/InventoryButton
@onready var quests_button: Button = $Panel/MarginContainer/VBox/TabBar/QuestsButton
@onready var system_button: Button = $Panel/MarginContainer/VBox/TabBar/SystemButton

@onready var party_panel: PartyPanel = $Panel/MarginContainer/VBox/MarginContainer/ContentArea/PartyPanel
@onready var inventory_panel: InventoryPanel = $Panel/MarginContainer/VBox/MarginContainer/ContentArea/InventoryPanel
@onready var quests_panel: QuestsPanel = $Panel/MarginContainer/VBox/MarginContainer/ContentArea/QuestsPanel
@onready var system_panel: SystemPanel = $Panel/MarginContainer/VBox/MarginContainer/ContentArea/SystemPanel

var _is_open: bool = false
var _current_tab: Tab = Tab.PARTY
var _tab_buttons: Dictionary = {}
var _panels: Dictionary[Tab, HudPanel] = {}

func _ready() -> void:
	_register_panel(Tab.PARTY, party_panel)
	_register_panel(Tab.INVENTORY, inventory_panel)
	_register_panel(Tab.QUESTS, quests_panel)
	_register_panel(Tab.SYSTEM, system_panel)
	_setup_tab_buttons()
	hide_hud()

func is_open() -> bool:
	return _is_open

func has_open_modal() -> bool:
	return system_panel.options_window.is_open()

func show_hud(start_tab: Tab = _current_tab) -> void:
	_is_open = true
	visible = true
	InputManager.push_menu_focus_context(
		panel,
		Callable(self, "_get_default_focus_target")
	)
	switch_tab(start_tab)

func hide_hud() -> void:
	_is_open = false
	visible = false
	InputManager.pop_menu_focus_context(panel)
	hud_closed.emit()

func switch_tab(tab: Tab) -> void:
	_current_tab = tab
	for panel_tab: Tab in _panels:
		_panels[panel_tab].visible = panel_tab == tab
	_sync_tab_buttons()
	_panels[tab].on_tab_opened()
	_focus_current_tab.call_deferred()

func _register_panel(tab: Tab, hud_panel: HudPanel) -> void:
	_panels[tab] = hud_panel

func _get_default_focus_target() -> Control:
	return _panels[_current_tab].get_default_focus_target()

func _focus_current_tab() -> void:
	if not _is_open:
		return
	var target := _get_default_focus_target()
	if target == null:
		target = _tab_buttons[_current_tab] as Button
	InputManager.focus_menu_control(target)

func _setup_tab_buttons() -> void:
	_tab_buttons = {
		Tab.PARTY: party_button,
		Tab.INVENTORY: inventory_button,
		Tab.QUESTS: quests_button,
		Tab.SYSTEM: system_button,
	}

	for tab in _tab_buttons:
		var btn: Button = _tab_buttons[tab]
		btn.toggle_mode = true
		btn.pressed.connect(switch_tab.bind(tab))

	_sync_tab_buttons()

func _switch_relative_tab(direction: int) -> void:
	var next_tab: Tab = wrapi(_current_tab + direction, 0, _panels.size()) as Tab
	switch_tab(next_tab)

func _sync_tab_buttons() -> void:
	for tab in _tab_buttons:
		var btn: Button = _tab_buttons[tab]
		btn.set_pressed_no_signal(tab == _current_tab)

func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or has_open_modal() or event.is_echo():
		return
	if event.is_action_pressed(&"tab_left"):
		_switch_relative_tab(-1)
	elif event.is_action_pressed(&"tab_right"):
		_switch_relative_tab(1)
	else:
		return
	get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	InputManager.pop_menu_focus_context(panel)
