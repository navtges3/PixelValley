extends Control
class_name HudPanel
## Base class for GameHUD tab panels.
## GameHUD only talks to panels through this contract:
##   on_tab_opened()             tab was switched to (default: refresh())
##   refresh()                   rebuild the view from game state
##   get_default_focus_target()  where focus lands (null = HUD focuses the tab button)
## Deliberately no _ready() here: an override without super() would silently
## skip it. Subclasses own their lifecycle.

var _focus_controls: Dictionary[String, Control] = {}
var _last_focus_key: String = ""

# ---- Contract ----

## Called by GameHUD every time this panel's tab becomes the current tab.
## Override to reset transient UI state, then call refresh() (or super()).
func on_tab_opened() -> void:
	refresh()

## Rebuild the view from game state. Must be safe to call repeatedly.
func refresh() -> void:
	pass

## Control that should receive focus when the tab opens. Default: the
## remembered control from the focus registry, else the first focusable one.
func get_default_focus_target() -> Control:
	return _focus_from_registry()

## Call after an in-panel action changed state: redraw, then restore focus.
func request_refresh() -> void:
	refresh()
	_restore_focus.call_deferred()

# ---- Opt-in focus memory ----

## Register a control under a stable key. Call from refresh() after
## _clear_focus_registry(); the last-focused key survives rebuilds.
func _register_focus(control: Control, key: String) -> void:
	_focus_controls[key] = control
	control.focus_entered.connect(func() -> void: _last_focus_key = key)

func _clear_focus_registry() -> void:
	_focus_controls.clear()

## Override: pick a nearby control when the remembered one is gone or disabled.
func _get_focus_fallback(_lost_key: String) -> Control:
	return null

func _focus_from_registry() -> Control:
	if not _last_focus_key.is_empty():
		var remembered: Control = _focus_controls.get(_last_focus_key)
		if can_receive_focus(remembered):
			return remembered
		var fallback := _get_focus_fallback(_last_focus_key)
		if can_receive_focus(fallback):
			return fallback
	for control: Control in _focus_controls.values():
		if can_receive_focus(control):
			return control
	return null

func _restore_focus() -> void:
	var target := get_default_focus_target()
	if target != null:
		InputManager.focus_menu_control_deferred(target)

# ---- Shared helpers ----

static func can_receive_focus(control: Control) -> bool:
	return (
		is_instance_valid(control)
		and control.is_inside_tree()
		and control.is_visible_in_tree()
		and control.focus_mode != Control.FOCUS_NONE
		and not (control is BaseButton and (control as BaseButton).disabled)
	)

## Removes children before freeing them so get_child_count() is accurate
## immediately (queue_free alone leaves them counted until end of frame).
## Pass immediate = true when the caller needs the nodes gone right now.
func clear_children(container: Node, immediate: bool = false) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		if immediate:
			child.free()
		else:
			child.queue_free()
