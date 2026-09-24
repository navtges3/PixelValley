extends HudPanel
class_name PartyPanel

func _get_focus_fallback(lost_key: String) -> Control:
	var parts := lost_key.split(":")
	if parts.size() < 3 or parts[0] not in ["active", "reserve"]:
		return null
	for list_name: String in ["active", "reserve"]:  # Add moves reserve -> active
		var c: Control = _focus_controls.get("%s:%s:select" % [list_name, parts[1]])
		if can_receive_focus(c):
			return c
	return null

func _run(action: Callable) -> void:
	if action.call() == true:
		SaveManager.save_party()
	request_refresh()
