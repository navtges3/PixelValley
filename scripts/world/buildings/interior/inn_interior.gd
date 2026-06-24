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
