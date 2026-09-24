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
func on_tab_opened() -> void:
	refresh()

func refresh() -> void:
	pass

func get_default_focus_target() -> Control:
	return _focus_from_registry()

## Call after an in-panel action changed state: redraw, then restore focus.
func request_refresh() -> void:
	refresh()
	_restore_focus.call_deferred()

# ---- Opt-in focus memory ----
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

## Removes before freeing so get_child_count() is accurate immediately
## (queue_free alone leaves children counted until end of frame).
func clear_children(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
