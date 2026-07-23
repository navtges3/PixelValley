extends Control
class_name TrackedQuestHUD

@onready var panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var objectives_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ObjectivesList
@onready var ready_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ReadyLabel

var _bound_manager: QuestManager = null
var _refresh_queued: bool = false

func _ready() -> void:
	GameState.quest_manager_changed.connect(_on_quest_manager_changed)
	_bind_quest_manager(GameState.quest_manager)
	refresh()

func _exit_tree() -> void:
	if GameState.quest_manager_changed.is_connected(_on_quest_manager_changed):
		GameState.quest_manager_changed.disconnect(_on_quest_manager_changed)
	_disconnect_quest_manager()

func _on_quest_manager_changed(manager: QuestManager) -> void:
	_bind_quest_manager(manager)
	refresh()

func refresh() -> void:
	if _bound_manager == null:
		hide()
		return
	var quest := _bound_manager.get_tracked_quest()
	if quest == null:
		hide()
		return
	title_label.text = quest.title
	ready_label.visible = _bound_manager.is_quest_ready(quest.id)
	for child: Node in objectives_list.get_children():
		child.free()
	for objective: QuestObjective in quest.objectives:
		var label := Label.new()
		label.text = "- %s" % objective.get_progress_text()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		objectives_list.add_child(label)
	show()
	_resize_panel_to_content()

func _resize_panel_to_content() -> void:
	await get_tree().process_frame
	panel.reset_size()

func _bind_quest_manager(manager: QuestManager) -> void:
	if _bound_manager == manager:
		return
	_disconnect_quest_manager()
	_bound_manager = manager
	if _bound_manager == null:
		return
	_bound_manager.tracked_quest_changed.connect(_on_tracked_quest_changed)
	_bound_manager.quest_progress_updated.connect(_on_quest_changed)
	_bound_manager.quest_ready_to_turn_in.connect(_on_quest_changed)

func _disconnect_quest_manager() -> void:
	if _bound_manager == null:
		return
	if _bound_manager.tracked_quest_changed.is_connected(_on_tracked_quest_changed):
		_bound_manager.tracked_quest_changed.disconnect(_on_tracked_quest_changed)
	if _bound_manager.quest_progress_updated.is_connected(_on_quest_changed):
		_bound_manager.quest_progress_updated.disconnect(_on_quest_changed)
	if _bound_manager.quest_ready_to_turn_in.is_connected(_on_quest_changed):
		_bound_manager.quest_ready_to_turn_in.disconnect(_on_quest_changed)
	_bound_manager = null

func _on_tracked_quest_changed(_quest_id: int) -> void:
	_queue_refresh()

func _on_quest_changed(_quest: Quest) -> void:
	_queue_refresh()

func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_apply_queued_refresh.call_deferred()

func _apply_queued_refresh() -> void:
	_refresh_queued = false
	refresh()
