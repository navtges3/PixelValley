extends BaseLocation
class_name InnInterior

const ENTRANCE_ID := "inn"

@onready var inn_window: InnWindow = $CanvasLayer/InnWindow
@onready var interact_area: InteractArea = $Props/Counter/InteractArea

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.INN

func _on_location_ready() -> void:
	interact_area.interacted.connect(_on_counter_interacted)
	inn_window.closed.connect(_on_window_closed)
	inn_window.hide()

func _on_counter_interacted() -> void:
	player.movement_blocked = true
	inn_window.open()

func _on_window_closed() -> void:
	player.movement_blocked = false

func _input(event: InputEvent) -> void:
	if inn_window.is_visible_in_tree():
		if event.is_action_pressed("open_hud") or event.is_action_pressed("ui_cancel"):
			inn_window.close()
	else:
		super._input(event)
