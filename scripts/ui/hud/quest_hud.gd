extends Control
class_name QuestHUD

@onready var panel: PanelContainer = $PanelContainer
@onready var quest_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/QuestList
@onready var toggle_button: Button = $ToggleButton

var _is_collapsed: bool = false

const COLOR_COMPLETE         := Color(0.25, 0.85, 0.35)
const COLOR_IN_PROGRESS      := Color(0.92, 0.87, 0.72)
const COLOR_OBJECTIVE_DONE   := Color(0.45, 0.90, 0.55)
const COLOR_OBJECTIVE_PENDING := Color(0.72, 0.67, 0.57)
const COLOR_SEPARATOR        := Color(0.4,  0.35, 0.3,  0.4)

func _ready() -> void:
	toggle_button.pressed.connect(_on_toggle_pressed)
	_connect_signals()
	_refresh()

func _connect_signals() -> void:
	if not GameState.monster_killed.is_connected(_on_monster_killed):
		GameState.monster_killed.connect(_on_monster_killed)

func _on_monster_killed(_monster_id: int, _location_id: String) -> void:
	# Wait one frame so QuestManager processes the kill first
	await get_tree().process_frame
	_refresh()

func _on_toggle_pressed() -> void:
	_is_collapsed = !_is_collapsed
	panel.visible = !_is_collapsed
	toggle_button.text = "▶ Quests" if _is_collapsed else "▼ Quests"

func _refresh() -> void:
	if GameState.quest_manager == null:
		return

	for child in quest_list.get_children():
		child.queue_free()

	var quests: Array = GameState.quest_manager.available_quests
	if quests.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No active quests"
		empty_label.add_theme_color_override("font_color", COLOR_OBJECTIVE_PENDING)
		empty_label.add_theme_font_size_override("font_size", 11)
		quest_list.add_child(empty_label)
		return

	for i in quests.size():
		quest_list.add_child(_build_quest_entry(quests[i], i < quests.size() - 1))

func _build_quest_entry(quest: Quest, add_separator: bool) -> Control:
	var complete := quest.all_objectives_met()
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var title := Label.new()
	title.text = quest.title
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", COLOR_COMPLETE if complete else COLOR_IN_PROGRESS)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(title)

	for objective in quest.monster_objectives:
		var done := objective.current_amount >= objective.target_amount
		var obj_line := Label.new()
		obj_line.text = "  • %s%s: %d/%d" % [
			_monster_name(objective.monster_id),
			_location_hint(objective.location_id),
			objective.current_amount,
			objective.target_amount,
		]
		obj_line.add_theme_font_size_override("font_size", 10)
		obj_line.add_theme_color_override(
			"font_color",
			COLOR_OBJECTIVE_DONE if done else COLOR_OBJECTIVE_PENDING
		)
		container.add_child(obj_line)

	if complete:
		var badge := Label.new()
		badge.text = "  ✓ Return to village to turn in"
		badge.add_theme_font_size_override("font_size", 10)
		badge.add_theme_color_override("font_color", COLOR_COMPLETE)
		container.add_child(badge)

	if add_separator:
		var sep := HSeparator.new()
		sep.add_theme_color_override("color", COLOR_SEPARATOR)
		container.add_child(sep)

	return container

func _monster_name(monster_id: int) -> String:
	var keys: Array = MonsterLoader.MonsterID.keys()
	if monster_id >= 0 and monster_id < keys.size():
		return (keys[monster_id] as String).replace("_", " ").capitalize()
	return "Monster %d" % monster_id

func _location_hint(location_id: String) -> String:
	if location_id.is_empty():
		return ""
	return " [%s]" % location_id.replace("_", " ").capitalize()
