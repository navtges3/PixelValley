extends Button
class_name QuestButton

const Y_OFFSET: float = 16.0
const MINIMUM_HEIGHT: float = 100.0

enum DisplayState { OFFERED, ACTIVE, READY, COMPLETED }

signal quest_selected(quest_id: int)

@onready var title_label: Label = $VBoxContainer/TitleRow/TitleLabel
@onready var category_label: Label = $VBoxContainer/TitleRow/CategoryLabel
@onready var state_label: Label = $VBoxContainer/StateLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var objectives_list: VBoxContainer = $VBoxContainer/ObjectivesList
@onready var content_container: VBoxContainer = $VBoxContainer

var _quest: Quest = null
var _display_state: DisplayState = DisplayState.ACTIVE
var _is_tracked: bool = false

func setup(quest: Quest, display_state: DisplayState, is_tracked: bool = false) -> void:
	_quest = quest
	_display_state = display_state
	_is_tracked = is_tracked

func _ready() -> void:
	_render()

func get_quest_id() -> int:
	return _quest.id if _quest != null else -1

func get_quest() -> Quest:
	return _quest

func _pressed() -> void:
	if _quest != null:
		quest_selected.emit(_quest.id)

func _render() -> void:
	if _quest == null:
		return
	title_label.text = _quest.title
	description_label.text = _quest.description
	category_label.text = _get_category_text()
	state_label.text = _get_state_text()
	if _is_tracked:
		state_label.text += " [Tracked]"
	state_label.add_theme_color_override("font_color", _get_state_color())
	for child: Node in objectives_list.get_children():
		child.free()
	for objective: QuestObjective in _quest.objectives:
		var objective_label := Label.new()
		objective_label.text = "- %s" % objective.get_progress_text()
		objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		objective_label.custom_minimum_size.x = description_label.custom_minimum_size.x
		objective_label.add_theme_color_override("font_color", Color(0.25, 0.85, 0.35) if objective.is_complete() else Color(0, 0, 0))
		objectives_list.add_child(objective_label)
	refresh_minimum_height()

func refresh_minimum_height() -> void:
	_update_size.call_deferred()

func _get_category_text() -> String:
	match _quest.category:
		Quest.Category.MAIN:
			return "Main Quest"
		Quest.Category.SIDE:
			return "Side Quest"
		_:
			return "Quest"

func _get_state_text() -> String:
	match _display_state:
		DisplayState.OFFERED:
			return "Available"
		DisplayState.ACTIVE:
			return "In Progress"
		DisplayState.READY:
			return "Ready to Turn In"
		DisplayState.COMPLETED:
			return "Completed"
		_:
			return ""

func _get_state_color() -> Color:
	match _display_state:
		DisplayState.OFFERED:
			return Color(0.95, 0.80, 0.25)
		DisplayState.ACTIVE:
			return Color(0.12, 0.32, 0.62)
		DisplayState.READY:
			return Color(0.25, 0.85, 0.35)
		DisplayState.COMPLETED:
			return Color(0.55, 0.70, 0.55)
		_:
			return Color.WHITE

func _update_size() -> void:
	custom_minimum_size.y = maxf(
		MINIMUM_HEIGHT,
		content_container.get_combined_minimum_size().y + Y_OFFSET
	)
