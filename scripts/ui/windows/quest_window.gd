extends GameWindow
class_name QuestWindow

const COLOR_HEADER = Color(0, 0, 0)

enum Tab { AVAILABLE, ACTIVE, COMPLETED }

@onready var available_button: Button = $PanelContainer/VBoxContainer/QuestTabs/AvailableButton
@onready var active_button: Button = $PanelContainer/VBoxContainer/QuestTabs/ActiveButton
@onready var completed_button: Button = $PanelContainer/VBoxContainer/QuestTabs/CompletedButton
@onready var quest_list: VBoxContainer = $PanelContainer/VBoxContainer/QuestScrollContainer/QuestList
@onready var action_button: Button = $PanelContainer/VBoxContainer/BottomControls/ActionButton
@onready var reward_window: RewardWindow = $RewardWindow

const QUEST_BUTTON := preload("res://scenes/ui/components/quest_button.tscn")

var _current_tab: Tab = Tab.AVAILABLE
var _selected_quest_id: int = -1
var _bound_manager: QuestManager = null
var _refresh_queued: bool = false
var _tab_group: ButtonGroup = ButtonGroup.new()
var _quest_group: ButtonGroup = ButtonGroup.new()
var _buttons_by_id: Dictionary[int, QuestButton] = {}

func _ready() -> void:
	super._ready()
	available_button.button_group = _tab_group
	active_button.button_group = _tab_group
	completed_button.button_group = _tab_group

	available_button.pressed.connect(_select_tab.bind(Tab.AVAILABLE))
	active_button.pressed.connect(_select_tab.bind(Tab.ACTIVE))
	completed_button.pressed.connect(_select_tab.bind(Tab.COMPLETED))

func open() -> void:
	_bind_quest_manager(GameState.quest_manager)
	_select_tab(Tab.AVAILABLE)
	super.open()

func _accept_selected_quest(quest: Quest) -> void:
	if GameState.quest_manager.accept_quest(quest):
		_current_tab = Tab.ACTIVE
		_selected_quest_id = quest.id
		_sync_tab_buttons()
		_refresh_quest_list()

func _add_category_section(quests: Array[Quest], category: Quest.Category, header_text: String) -> void:
	var matching_quests: Array[Quest] = GameState.quest_manager.filter_quests_by_category(quests, category)
	if matching_quests.is_empty():
		return
	matching_quests.sort_custom(_sort_quests_by_id)
	var header := Label.new()
	header.text = header_text
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", COLOR_HEADER)
	quest_list.add_child(header)
	for quest: Quest in matching_quests:
		_add_quest_button(quest)

func _add_empty_message(message: String) -> void:
	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", COLOR_HEADER)
	quest_list.add_child(label)

func _add_quest_button(quest: Quest) -> void:
	var quest_button := QUEST_BUTTON.instantiate() as QuestButton
	var display_state := _get_display_state(quest)
	quest_button.setup(quest, display_state)
	quest_button.button_group = _quest_group
	quest_button.quest_selected.connect(_on_quest_selected)
	quest_list.add_child(quest_button)
	_buttons_by_id[quest.id] = quest_button
	if quest.id == _selected_quest_id:
		quest_button.set_pressed_no_signal(true)

func _apply_queued_refresh() -> void:
	_refresh_queued = false
	_refresh_quest_list()
	_update_action_button()

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

func _clear_quest_list() -> void:
	for child: Node in quest_list.get_children():
		child.free()

func _clear_selection() -> void:
	_selected_quest_id = -1
	_update_action_button()

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
	_bound_manager = null

func _exit_tree() -> void:
	_disconnect_quest_manager()

func _get_current_quests() -> Array[Quest]:
	var quests: Array[Quest] = []
	var manager: QuestManager = GameState.quest_manager
	match _current_tab:
		Tab.AVAILABLE:
			quests.append_array(manager.get_offered_quests())
		Tab.ACTIVE:
			quests.append_array(manager.get_active_quests())
			quests.append_array(manager.get_ready_quests())
		Tab.COMPLETED:
			quests.append_array(manager.get_completed_quests())
	return quests

func _get_default_focus_target() -> Control:
	return available_button

func _get_display_state(quest: Quest) -> QuestButton.DisplayState:
	var manager: QuestManager = GameState.quest_manager
	if manager.is_quest_offered(quest.id):
		return QuestButton.DisplayState.OFFERED
	if manager.is_quest_active(quest.id):
		return QuestButton.DisplayState.ACTIVE
	if manager.is_quest_ready(quest.id):
		return QuestButton.DisplayState.READY
	if manager.is_quest_completed(quest.id):
		return QuestButton.DisplayState.COMPLETED
	push_warning("QuestWindow: quest %d has no visible lifecycle state" % quest.id)
	return QuestButton.DisplayState.ACTIVE

func _get_empty_message() -> String:
	match _current_tab:
		Tab.AVAILABLE:
			return "No quests are currently available."
		Tab.ACTIVE:
			return "No active quests."
		Tab.COMPLETED:
			return "No completed quests yet."
		_:
			return "No quests."

func _get_focused_quest_id() -> int:
	for quest_id: int in _buttons_by_id:
		var button: QuestButton = _buttons_by_id[quest_id]
		if button.has_focus():
			return quest_id
	return -1

func _on_action_button_pressed() -> void:
	if GameState.quest_manager == null:
		return
	var manager: QuestManager = GameState.quest_manager
	var quest := manager.get_quest_by_id(_selected_quest_id)
	if quest == null:
		_clear_selection()
		return
	if manager.is_quest_offered(_selected_quest_id):
		_accept_selected_quest(quest)
	elif manager.is_quest_ready(_selected_quest_id):
		_turn_in_selected_quest(quest)

func _on_close_button_pressed() -> void:
	close()

func _on_quest_changed(_quest: Quest) -> void:
	_queue_refresh()

func _on_quest_selected(quest_id: int) -> void:
	_selected_quest_id = quest_id
	_update_action_button()

func _on_quest_turned_in(_quest: Quest, _rewards: Array[RewardEntry]) -> void:
	_queue_refresh()

func _on_reward_window_collected() -> void:
	if is_open():
		available_button.grab_focus.call_deferred()

func _queue_refresh() -> void:
	if _refresh_queued or not is_visible_in_tree():
		return
	_refresh_queued = true
	_apply_queued_refresh.call_deferred()

func _refresh_quest_list() -> void:
	var focused_quest_id := _get_focused_quest_id()
	var restore_list_focus := focused_quest_id >= 0
	_clear_quest_list()
	_quest_group = ButtonGroup.new()
	_buttons_by_id.clear()
	if GameState.quest_manager == null:
		_add_empty_message("Quest information is unavailable.")
		return
	var quests: Array[Quest] = _get_current_quests()
	_add_category_section(quests, Quest.Category.MAIN, "Main Quests")
	_add_category_section(quests, Quest.Category.SIDE, "Side Quests")
	if quests.is_empty():
		_add_empty_message(_get_empty_message())
	if restore_list_focus:
		_restore_focus_after_refresh.call_deferred(focused_quest_id)

func _restore_focus_after_refresh(preferred_quest_id: int) -> void:
	var preferred_button: QuestButton = _buttons_by_id.get(preferred_quest_id)
	if preferred_button != null:
		preferred_button.grab_focus()
		return
	if not _buttons_by_id.is_empty():
		var first_button := _buttons_by_id.values()[0] as QuestButton
		first_button.grab_focus()

func _select_tab(tab: Tab) -> void:
	_current_tab = tab
	_selected_quest_id = -1
	_sync_tab_buttons()
	_update_action_button()
	_refresh_quest_list()

func _sort_quests_by_id(a: Quest, b: Quest) -> bool:
	return a.id < b.id

func _sync_tab_buttons() -> void:
	available_button.set_pressed_no_signal(_current_tab == Tab.AVAILABLE)
	active_button.set_pressed_no_signal(_current_tab == Tab.ACTIVE)
	completed_button.set_pressed_no_signal(_current_tab == Tab.COMPLETED)

func _turn_in_selected_quest(quest: Quest) -> void:
	if not GameState.quest_manager.is_quest_ready(quest.id):
		return
	var rewards: Array[RewardEntry] = GameState.quest_manager.turn_in_quest(quest)
	_selected_quest_id = -1
	_update_action_button()
	reward_window.show_rewards("Quest Complete!", rewards)

func _update_action_button() -> void:
	var manager: QuestManager = GameState.quest_manager
	if manager == null or _selected_quest_id < 0:
		action_button.disabled = true
		action_button.text = "Select a Quest"
		return
	if manager.is_quest_offered(_selected_quest_id):
		action_button.disabled = false
		action_button.text = "Accept"
		return
	if manager.is_quest_ready(_selected_quest_id):
		action_button.disabled = false
		action_button.text = "Turn In"
		return
	if manager.is_quest_active(_selected_quest_id):
		action_button.disabled = true
		action_button.text = "In Progress"
		return
	if manager.is_quest_completed(_selected_quest_id):
		action_button.disabled = true
		action_button.text = "Completed"
		return
	action_button.disabled = true
	action_button.text = "Unavailable"
