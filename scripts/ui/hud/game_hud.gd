extends CanvasLayer
class_name GameHUD

enum Tab {
	STATS,
	INVENTORY,
	QUESTS,
	SYSTEM,
}

const TAB_LABELS := {
	Tab.STATS:     "Stats",
	Tab.INVENTORY: "Inventory",
	Tab.QUESTS:    "Quests",
	Tab.SYSTEM:    "System",
}

const PANELS_BY_TAB := {
	Tab.STATS: "StatsPanel",
	Tab.INVENTORY: "InventoryPanel",
	Tab.QUESTS: "QuestsPanel",
	Tab.SYSTEM: "SystemPanel",
}

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Panel
@onready var tab_bar: HBoxContainer = $Panel/VBox/TabBar
@onready var content_area: Control = $Panel/VBox/ContentArea

@onready var stats_panel: Control = $Panel/VBox/ContentArea/StatsPanel
@onready var inventory_panel: Control = $Panel/VBox/ContentArea/InventoryPanel
@onready var quests_panel: Control = $Panel/VBox/ContentArea/QuestsPanel
@onready var system_panel: Control = $Panel/VBox/ContentArea/SystemPanel

var _is_open: bool = false
var _current_tab: Tab = Tab.STATS
var _tab_buttons: Dictionary = {}

const COLOR_TAB_ACTIVE   := Color(0.95, 0.88, 0.68, 1.0)
const COLOR_TAB_INACTIVE := Color(0.55, 0.50, 0.42, 1.0)
const COLOR_TAB_BG_ACTIVE   := Color(0.22, 0.18, 0.14, 1.0)
const COLOR_TAB_BG_INACTIVE := Color(0.12, 0.10, 0.08, 0.85)

signal hud_closed

func _ready() -> void:
	_build_tab_buttons()
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
	for t in _tab_buttons:
		var btn: Button = _tab_buttons[t]
		_style_tab_button(btn, t == tab)
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

func _build_tab_buttons() -> void:
	for child in tab_bar.get_children():
		child.queue_free()
	for tab in TAB_LABELS:
		var btn := Button.new()
		btn.text = TAB_LABELS[tab]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 32)
		_style_tab_button(btn, false)
		btn.pressed.connect(switch_tab.bind(tab))
		tab_bar.add_child(btn)
		_tab_buttons[tab] = btn

func _style_tab_button(btn: Button, active: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_TAB_BG_ACTIVE if active else COLOR_TAB_BG_INACTIVE
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.border_width_bottom = 2 if active else 0
	normal.border_color = Color(0.85, 0.72, 0.45)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", normal)
	btn.add_theme_stylebox_override("pressed", normal)
	btn.add_theme_color_override("font_color", COLOR_TAB_ACTIVE if active else COLOR_TAB_INACTIVE)
	btn.add_theme_font_size_override("font_size", 13)
