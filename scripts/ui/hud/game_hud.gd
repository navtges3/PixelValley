extends CanvasLayer
class_name GameHUD

enum Tab {
	STATS,
	INVENTORY,
	QUESTS,
	SYSTEM,
}

const PANELS_BY_TAB := {
	Tab.STATS:     "StatsPanel",
	Tab.INVENTORY: "InventoryPanel",
	Tab.QUESTS:    "QuestsPanel",
	Tab.SYSTEM:    "SystemPanel",
}

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Panel
@onready var content_area: Control = $Panel/MarginContainer/VBox/MarginContainer/ContentArea

@onready var stats_button: Button = $Panel/MarginContainer/VBox/TabBar/StatsButton
@onready var inventory_button: Button = $Panel/MarginContainer/VBox/TabBar/InventoryButton
@onready var quests_button: Button = $Panel/MarginContainer/VBox/TabBar/QuestsButton
@onready var system_button: Button = $Panel/MarginContainer/VBox/TabBar/SystemButton

@onready var stats_panel: StatsPanel = $Panel/MarginContainer/VBox/MarginContainer/ContentArea/StatsPanel
@onready var inventory_panel: InventoryPanel = $Panel/MarginContainer/VBox/MarginContainer/ContentArea/InventoryPanel
@onready var quests_panel: QuestsPanel = $Panel/MarginContainer/VBox/MarginContainer/ContentArea/QuestsPanel
@onready var system_panel: SystemPanel = $Panel/MarginContainer/VBox/MarginContainer/ContentArea/SystemPanel

var _is_open: bool = false
var _current_tab: Tab = Tab.STATS
var _tab_buttons: Dictionary = {}

signal hud_closed

func _ready() -> void:
	_setup_tab_buttons()
	hide_hud()

func is_open() -> bool:
	return _is_open

func show_hud(start_tab: Tab = _current_tab) -> void:
	_is_open = true
	visible = true
	switch_tab(start_tab)

func hide_hud() -> void:
	_is_open = false
	visible = false
	hud_closed.emit()

func switch_tab(tab: Tab) -> void:
	_current_tab = tab
	for panel_name in PANELS_BY_TAB.values():
		content_area.get_node(panel_name).visible = false
	content_area.get_node(PANELS_BY_TAB[tab]).visible = true
	_sync_tab_buttons()
	_refresh_current_tab()

func _refresh_current_tab() -> void:
	match _current_tab:
		Tab.STATS:
			stats_panel.refresh()
		Tab.INVENTORY:
			inventory_panel.refresh()
		Tab.QUESTS:
			quests_panel.refresh()
		Tab.SYSTEM:
			system_panel.refresh()

func _setup_tab_buttons() -> void:
	_tab_buttons = {
		Tab.STATS: stats_button,
		Tab.INVENTORY: inventory_button,
		Tab.QUESTS: quests_button,
		Tab.SYSTEM: system_button,
	}

	for tab in _tab_buttons:
		var btn: Button = _tab_buttons[tab]
		btn.toggle_mode = true
		btn.pressed.connect(switch_tab.bind(tab))

	_sync_tab_buttons()

func _sync_tab_buttons() -> void:
	for tab in _tab_buttons:
		var btn: Button = _tab_buttons[tab]
		btn.set_pressed_no_signal(tab == _current_tab)
