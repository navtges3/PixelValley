extends Control
class_name QuestsPanel

@onready var active_list: VBoxContainer = $ScrollContainer/VBoxContainer/ActiveList
@onready var completed_header: Label = $ScrollContainer/VBoxContainer/CompletedHeader
@onready var completed_list: VBoxContainer = $ScrollContainer/VBoxContainer/CompletedList

const COLOR_HEADER         := Color(0.95, 0.92, 0.80)
const COLOR_COMPLETE       := Color(0.25, 0.85, 0.35)
const COLOR_IN_PROGRESS    := Color(0.92, 0.87, 0.72)
const COLOR_OBJECTIVE_DONE := Color(0.45, 0.90, 0.55)
const COLOR_OBJECTIVE_PEND := Color(0.72, 0.67, 0.57)
const COLOR_SEPARATOR      := Color(0.4,  0.35, 0.3,  0.5)

func refresh() -> void:
	if GameState.quest_manager == null:
		return
	_refresh_active()
	_refresh_completed()

func _refresh_active() -> void:
	for child in active_list.get_children():
		child.queue_free()
	
	var quests := GameState.quest_manager.available_quests
	if quests.is_empty():
		active_list.add_child(_make_label("No active quests.", COLOR_OBJECTIVE_PEND, 11))
		return
	
	for i in quests.size():
		active_list.add_child(_build_quest_entry(quests[i], i < quests.size() - 1))

func _refresh_completed() -> void:
	for child in completed_list.get_children():
		child.queue_free()
	
	var quests := GameState.quest_manager.completed_quests
	completed_header.text = "Completed Quests (%d)" % quests.size()
	completed_header.add_theme_color_override("font_color", COLOR_COMPLETE)
	
	if quests.is_empty():
		completed_list.add_child(_make_label("None yet.", COLOR_OBJECTIVE_PEND, 11))
		return
	
	for quest in quests:
		var lbl := _make_label("✓ %s" % quest.title, COLOR_COMPLETE, 11)
		completed_list.add_child(lbl)

func _build_quest_entry(quest: Quest, add_separator: bool) -> Control:
	var complete := quest.all_objectives_met()
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	
	var title := _make_label(quest.title, COLOR_COMPLETE if complete else COLOR_IN_PROGRESS, 13)
	container.add_child(title)
	
	var desc := _make_label(quest.description, COLOR_OBJECTIVE_PEND, 10)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(desc)
	
	for objective in quest.objectives:
		var done := objective.current_amount >= objective.target_amount
		var hint := ""
		if not objective.location_id.is_empty():
			hint = " [%s]" % objective.location_id.replace("_", " ").capitalize()
		var obj_text := "  • %s%s: %d/%d" % [
			_monster_name(objective.monster_id), hint,
			objective.current_amount, objective.target_amount
		]
		var obj_lbl := _make_label(obj_text, COLOR_OBJECTIVE_DONE if done else COLOR_OBJECTIVE_PEND, 11)
		container.add_child(obj_lbl)
	
	if complete:
		var badge := _make_label("  ✓ Ready to turn in at the village!", COLOR_COMPLETE, 10)
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

func _make_label(txt: String, color: Color, font_size: int = 12) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	return lbl
