extends BaseLocation
class_name VillageLocation

@onready var exit_trigger_zone: TriggerZone = $TriggerZones/ExitTriggerZone
@onready var quest_interact_area: InteractArea = $Props/QuestBoard/InteractArea
@onready var quest_window: QuestWindow = $CanvasLayer/QuestWindow

func _get_screen_name() -> ScreenManager.ScreenName:
	return ScreenManager.ScreenName.VILLAGE

func _on_location_ready() -> void:
	exit_trigger_zone.screen_target = ScreenManager.ScreenName.VALLEY
	quest_interact_area.interacted.connect(_on_quest_board_interacted)
	quest_window.closed.connect(_on_window_closed)
	quest_window.hide()

func _on_quest_board_interacted() -> void:
	player.movement_blocked = true
	quest_window.open()

func _on_window_closed() -> void:
	player.movement_blocked = false

func _input(event: InputEvent) -> void:
	if quest_window.is_visible_in_tree():
		if event.is_action_pressed("open_hud") or event.is_action_pressed("ui_cancel"):
			quest_window.close()
	else:
		super._input(event)
