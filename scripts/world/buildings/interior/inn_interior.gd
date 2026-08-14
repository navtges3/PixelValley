extends BaseLocation
class_name InnInterior

const ENTRANCE_ID := "inn"
const SERVICE_ID: StringName = &"inn"

@onready var inn_window: InnWindow = $Foreground/CanvasLayer/InnWindow

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.INN

func _on_location_ready() -> void:
	inn_window.closed.connect(_on_window_closed)
	inn_window.close()

func _handle_npc_service_request(npc_id: StringName, service_id: StringName) -> void:
	if service_id != SERVICE_ID:
		super._handle_npc_service_request(npc_id, service_id)
		return
	player.movement_blocked = true
	inn_window.open()

func _on_window_closed() -> void:
	player.movement_blocked = false

func _input(event: InputEvent) -> void:
	if _handle_window_input(event, inn_window):
		return
	else:
		super._input(event)
