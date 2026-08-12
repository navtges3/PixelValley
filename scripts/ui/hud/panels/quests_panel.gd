extends Control
class_name QuestsPanel

const QUEST_BUTTON := preload("res://scenes/ui/components/quest_button.tscn")

const COLOR_HEADER         := Color(0.95, 0.92, 0.80)
const COLOR_OBJECTIVE_PEND := Color(0.72, 0.67, 0.57)

signal quest_selected(quest_id: int)

@onready var active_list: VBoxContainer = $VBoxContainer/ScrollContainer/QuestList/ActiveList
@onready var completed_header: Button = $VBoxContainer/ScrollContainer/QuestList/CompletedHeader
@onready var completed_list: VBoxContainer = $VBoxContainer/ScrollContainer/QuestList/CompletedList
@onready var track_button: Button = $VBoxContainer/ActionRow/TrackButton

var _bound_manager: QuestManager = null
var _buttons_by_id: Dictionary[int, QuestButton] = {}
var _completed_list_expanded: bool = false
var _completed_quest_count: int = 0
var _last_focused_quest_id: int = -1
var _selected_quest_id: int = -1
var _selection_group: ButtonGroup = ButtonGroup.new()
var _refresh_queued: bool = false

var _active_buttons: Array[QuestButton] = []
var _completed_buttons: Array[QuestButton] = []

func _ready() -> void:
	GameState.quest_manager_changed.connect(_on_quest_manager_changed)
	_bind_quest_manager(GameState.quest_manager)
	_refresh_track_action()
	refresh()

func get_default_focus_target() -> Control:
	var last_focused: QuestButton = _buttons_by_id.get(_last_focused_quest_id)
	if _can_receive_focus(last_focused):
		return last_focused
	var selected: QuestButton = _buttons_by_id.get(_selected_quest_id)
	if _can_receive_focus(selected):
		return selected
	var focus_chain := _get_focus_chain()
	if not focus_chain.is_empty():
		return focus_chain[0]
	return null

func refresh() -> void:
	var focused_quest_id := _get_focused_quest_id()
	var restore_list_focus := focused_quest_id >= 0
	_clear_container(active_list)
	_clear_container(completed_list)
	_selection_group = ButtonGroup.new()
	_buttons_by_id.clear()
	_active_buttons.clear()
	_completed_buttons.clear()
	if GameState.quest_manager == null:
		active_list.add_child(_make_label("Quest information is unavailable.", COLOR_OBJECTIVE_PEND, 11))
		_completed_quest_count = 0
		_sync_completed_section()
		_refresh_track_action()
		_configure_focus_graph()
		return
	_refresh_active()
	_refresh_completed()
	_validate_selection()
	_refresh_track_action()
	_configure_focus_graph()
	if restore_list_focus:
		_restore_focus_after_refresh.call_deferred(focused_quest_id)

func _add_category_group(parent: VBoxContainer, quests: Array[Quest], category: Quest.Category, title: String, state: QuestButton.DisplayState) -> void:
	var matching: Array[Quest] = GameState.quest_manager.filter_quests_by_category(quests, category)
	if matching.is_empty():
		return
	matching.sort_custom(_sort_quests_by_id)
	var header := _make_label(title, COLOR_HEADER, 13)
	parent.add_child(header)
	for quest: Quest in matching:
		_add_quest_button(parent, quest, state)

func _add_quest_button(parent: VBoxContainer, quest: Quest, state: QuestButton.DisplayState) -> void:
	var button := QUEST_BUTTON.instantiate() as QuestButton
	var is_tracked := quest.id == GameState.quest_manager.tracked_quest_id
	button.setup(quest, state, is_tracked)
	button.button_group = _selection_group
	button.quest_selected.connect(_on_quest_selected)
	button.focus_entered.connect(_on_quest_button_focused.bind(quest.id))
	parent.add_child(button)
	_buttons_by_id[quest.id] = button
	if state == QuestButton.DisplayState.COMPLETED:
		_completed_buttons.append(button)
	else:
		_active_buttons.append(button)
	if quest.id == _selected_quest_id:
		button.set_pressed_no_signal(true)

func _can_receive_focus(control: Control) -> bool:
	return (
		is_instance_valid(control)
		and control.is_visible_in_tree()
		and control.focus_mode != Control.FOCUS_NONE
		and not (control is BaseButton and (control as BaseButton).disabled)
	)

func _configure_focus_graph() -> void:
	var controls := _get_focus_chain()
	for index: int in controls.size():
		var control: Control = controls[index]
		control.focus_neighbor_top = NodePath()
		control.focus_neighbor_bottom = NodePath()
		if index > 0:
			control.focus_neighbor_top = control.get_path_to(controls[index - 1])
		if index < controls.size() - 1:
			control.focus_neighbor_bottom = control.get_path_to(controls[index + 1])

func _get_focus_chain() -> Array[Control]:
	var controls: Array[Control] = []
	for button: QuestButton in _active_buttons:
		if _can_receive_focus(button):
			controls.append(button)
	if _can_receive_focus(completed_header):
		controls.append(completed_header)
	if _completed_list_expanded:
		for button: QuestButton in _completed_buttons:
			if _can_receive_focus(button):
				controls.append(button)
	if _can_receive_focus(track_button):
		controls.append(track_button)
	return controls

func _apply_queued_refresh() -> void:
	_refresh_queued = false
	refresh()

func _bind_quest_manager(manager: QuestManager) -> void:
	if _bound_manager == manager:
		return
	_disconnect_quest_manager()
	_bound_manager = manager
	if _bound_manager == null:
		return
	_bound_manager.quest_offered.connect(_on_quest_changed)
	_bound_manager.quest_accepted.connect(_on_quest_changed)
	_bound_manager.quest_abandoned.connect(_on_quest_changed)
	_bound_manager.quest_progress_updated.connect(_on_quest_changed)
	_bound_manager.quest_ready_to_turn_in.connect(_on_quest_changed)
	_bound_manager.quest_turned_in.connect(_on_quest_turned_in)
	_bound_manager.tracked_quest_changed.connect(_on_tracked_quest_changed)

func _clear_container(list: VBoxContainer) -> void:
	for child: Node in list.get_children():
		child.free()

func _disconnect_quest_manager() -> void:
	if _bound_manager == null:
		return
	if _bound_manager.quest_offered.is_connected(_on_quest_changed):
		_bound_manager.quest_offered.disconnect(_on_quest_changed)
	if _bound_manager.quest_accepted.is_connected(_on_quest_changed):
		_bound_manager.quest_accepted.disconnect(_on_quest_changed)
	if _bound_manager.quest_abandoned.is_connected(_on_quest_changed):
		_bound_manager.quest_abandoned.disconnect(_on_quest_changed)
	if _bound_manager.quest_progress_updated.is_connected(_on_quest_changed):
		_bound_manager.quest_progress_updated.disconnect(_on_quest_changed)
	if _bound_manager.quest_ready_to_turn_in.is_connected(_on_quest_changed):
		_bound_manager.quest_ready_to_turn_in.disconnect(_on_quest_changed)
	if _bound_manager.quest_turned_in.is_connected(_on_quest_turned_in):
		_bound_manager.quest_turned_in.disconnect(_on_quest_turned_in)
	if _bound_manager.tracked_quest_changed.is_connected(_on_tracked_quest_changed):
		_bound_manager.tracked_quest_changed.disconnect(_on_tracked_quest_changed)
	_bound_manager = null
	
func _exit_tree() -> void:
	_disconnect_quest_manager()

func _get_focused_quest_id() -> int:
	for quest_id: int in _buttons_by_id:
		var button: QuestButton = _buttons_by_id[quest_id]
		if button.has_focus():
			return quest_id
	return -1

func _make_label(txt: String, color: Color, font_size: int = 12) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	return lbl

func _on_completed_header_toggled(expanded: bool) -> void:
	_completed_list_expanded = expanded
	_sync_completed_section()
	_configure_focus_graph()
	completed_header.grab_focus.call_deferred()

func _on_quest_button_focused(quest_id: int) -> void:
	_last_focused_quest_id = quest_id

func _on_quest_changed(_quest: Quest) -> void:
	_queue_refresh()

func _on_quest_manager_changed(manager: QuestManager) -> void:
	_bind_quest_manager(manager)
	refresh()

func _on_quest_selected(quest_id: int) -> void:
	_selected_quest_id = quest_id
	_refresh_track_action()
	_configure_focus_graph()
	quest_selected.emit(quest_id)

func _on_quest_turned_in(_quest: Quest, _rewards: Array[RewardEntry]) -> void:
	_queue_refresh()

func _on_track_button_pressed() -> void:
	var manager := GameState.quest_manager
	if manager == null or _selected_quest_id < 0:
		return
	if manager.tracked_quest_id == _selected_quest_id:
		manager.untrack_quest()
		SaveManager.save_game()
	elif manager.track_quest(_selected_quest_id):
		SaveManager.save_game()
	_refresh_track_action()
	track_button.grab_focus()

func _on_tracked_quest_changed(_quest_id: int) -> void:
	_queue_refresh()

func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_apply_queued_refresh.call_deferred()

func _refresh_active() -> void:
	var active_quests: Array[Quest] = GameState.quest_manager.get_active_quests()
	var ready_quests: Array[Quest] = GameState.quest_manager.get_ready_quests()
	_add_category_group(active_list, active_quests, Quest.Category.MAIN, "Main Quests", QuestButton.DisplayState.ACTIVE)
	_add_category_group(active_list, ready_quests, Quest.Category.MAIN, "Main Quests - Ready", QuestButton.DisplayState.READY)
	_add_category_group(active_list, active_quests, Quest.Category.SIDE, "Side Quests", QuestButton.DisplayState.ACTIVE)
	_add_category_group(active_list, ready_quests, Quest.Category.SIDE, "Side Quests - Ready", QuestButton.DisplayState.READY)
	if active_quests.is_empty() and ready_quests.is_empty():
		active_list.add_child(_make_label("No active quests.", COLOR_OBJECTIVE_PEND, 11))

func _refresh_completed() -> void:
	var quests: Array[Quest] = GameState.quest_manager.get_completed_quests()
	_completed_quest_count = quests.size()
	if quests.is_empty():
		_completed_list_expanded = false
		_sync_completed_section()
		return
	_add_category_group(completed_list, quests, Quest.Category.MAIN, "Main Quests", QuestButton.DisplayState.COMPLETED)
	_add_category_group(completed_list, quests, Quest.Category.SIDE, "Side Quests", QuestButton.DisplayState.COMPLETED)
	_sync_completed_section()

func _refresh_track_action() -> void:
	var manager := GameState.quest_manager
	if manager == null or _selected_quest_id < 0:
		track_button.text = "Track Quest"
		track_button.disabled = true
		return
	var trackable := manager.is_quest_active(_selected_quest_id) or manager.is_quest_ready(_selected_quest_id)
	track_button.disabled = not trackable
	if manager.tracked_quest_id == _selected_quest_id:
		track_button.text = "Untrack Quest"
	else:
		track_button.text = "Track Quest"

func _restore_focus_after_refresh(preferred_quest_id: int) -> void:
	var preferred_button: QuestButton = _buttons_by_id.get(preferred_quest_id)
	if _can_receive_focus(preferred_button):
		preferred_button.grab_focus()
		return
	var fallback := get_default_focus_target()
	if _can_receive_focus(fallback):
		fallback.grab_focus()

func _sort_quests_by_id(a: Quest, b: Quest) -> bool:
	return a.id < b.id

func _sync_completed_section() -> void:
	if _completed_quest_count == 0:
		_completed_list_expanded = false
	completed_header.disabled = _completed_quest_count == 0
	completed_list.visible = (
		_completed_list_expanded and _completed_quest_count > 0
	)
	completed_header.set_pressed_no_signal(_completed_list_expanded)
	var indicator := "[-]" if _completed_list_expanded else "[+]"
	completed_header.text = "%s Completed Quests (%d)" % [indicator, _completed_quest_count]
	if completed_list.visible:
		for button: QuestButton in _completed_buttons:
			button.refresh_minimum_height()

func _validate_selection() -> void:
	if _selected_quest_id < 0:
		return
	if not _buttons_by_id.has(_selected_quest_id):
		_selected_quest_id = -1
