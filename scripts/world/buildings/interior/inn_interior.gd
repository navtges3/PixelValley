extends BaseLocation
class_name InnInterior

const SCREEN_NAME := ScreenManager.ScreenName.INN

@onready var inn_window: InnWindow = $InnWindow
@onready var interact_area: InteractArea = $InteractArea

func _get_screen_name() -> ScreenManager.ScreenName:
	return SCREEN_NAME

func _on_location_ready() -> void:
	interact_area.interacted.connect(_on_counter_interacted)
	inn_window.closed.connect(_on_window_closed)
	inn_window.hide()

func _on_counter_interacted() -> void:
	player.movement_blocked = true
	inn_window.open()

func _on_window_closed() -> void:
	player.movement_blocked = false
