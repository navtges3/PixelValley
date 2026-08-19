extends GameWindow
class_name RewardWindow

signal rewards_collected()

@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var reward_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/RewardList
@onready var collect_button: Button = $PanelContainer/MarginContainer/VBoxContainer/CollectButton

func _ready() -> void:
	super._ready()
	collect_button.pressed.connect(_on_collect_pressed)

func show_rewards(win_title: String, rewards: Array[RewardEntry]) -> void:
	if rewards.is_empty():
		if is_open():
			close()
		rewards_collected.emit()
		return
	title_label.text = win_title
	_clear_list()
	for entry in rewards:
		reward_list.add_child(_build_entry(entry))
	open()

func _build_entry(entry: RewardEntry) -> Label:
	var label := Label.new()
	label.text = entry.display_text
	label.add_theme_color_override("font_color", entry.color)
	label.add_theme_font_size_override("font_size", 14)
	return label

func _clear_list() -> void:
	for child in reward_list.get_children():
		child.queue_free()

func _get_default_focus_target() -> Control:
	return collect_button

func _handle_cancel() -> void:
	_on_collect_pressed()

func _on_collect_pressed() -> void:
	close()
	rewards_collected.emit()
