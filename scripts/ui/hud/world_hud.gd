extends CanvasLayer
class_name WorldHUD

enum RewardFlow { NONE, DIALOGUE, WORLD_CONTAINER, }

@export_group("Dialogue Audio")
@export var dialogue_open_sfx_id: StringName = &""
@export var dialogue_advance_sfx_id: StringName = &""
@export var dialogue_response_sfx_id: StringName = &""
@export var dialogue_close_sfx_id: StringName = &""

signal dialogue_opened
signal dialogue_closed(reason: DialogueRunner.FinishReason)
signal dialogue_action_requested(action: DialogueAction, context: Dictionary[StringName, Variant])
signal world_rewards_opened
signal world_rewards_closed

@onready var game_hud: GameHUD = $GameHud
@onready var hero_hud: HeroHUD = $HeroHUD
@onready var tracked_quest_hud: TrackedQuestHUD = $TrackedQuestHUD

@onready var acquisition_notification: AcquisitionNotification = $AcquisitionLayer/AcquisitionNotification
@onready var dialogue_window: DialogueWindow = $DialogueLayer/DialogueWindow
@onready var reward_window: RewardWindow = $RewardLayer/RewardWindow

var dialogue_runner: DialogueRunner
var _pending_quest_rewards: Array[RewardEntry] = []
var _pending_finish_reason: DialogueRunner.FinishReason = DialogueRunner.FinishReason.COMPLETED
var _reward_flow: RewardFlow = RewardFlow.NONE

func _ready() -> void:
	dialogue_runner = DialogueRunner.new()
	dialogue_runner.dialogue_started.connect(_on_dialogue_started)
	dialogue_runner.sequence_started.connect(_on_sequence_started)
	dialogue_runner.line_changed.connect(_on_dialogue_line_changed)
	dialogue_runner.responses_changed.connect(dialogue_window.show_responses)
	dialogue_runner.response_selected.connect(_on_dialogue_response_selected)
	dialogue_runner.action_requested.connect(dialogue_action_requested.emit)
	dialogue_runner.dialogue_finished.connect(_on_dialogue_finished)
	dialogue_window.advance_requested.connect(dialogue_runner.advance)
	dialogue_window.response_requested.connect(dialogue_runner.choose_response)
	dialogue_window.cancel_requested.connect(dialogue_runner.cancel)
	reward_window.rewards_collected.connect(_on_rewards_collected)
	dialogue_window.close()
	reward_window.hide()

func hide_all() -> void:
	abort_dialogue()
	acquisition_notification.clear()
	hide()
	game_hud.hide_hud()
	for child in get_children():
		if child is Control:
			child.visible = false

func show_all() -> void:
	show()
	for child in get_children():
		if child is Control:
			child.visible = true
	tracked_quest_hud.refresh()

func show_world_rewards(win_title: String, rewards: Array[RewardEntry]) -> bool:
	if rewards.is_empty():
		return false
	if reward_window.is_open() or dialogue_runner.is_running() or game_hud.is_open():
		return false
	_reward_flow = RewardFlow.WORLD_CONTAINER
	reward_window.show_rewards(win_title, rewards)
	world_rewards_opened.emit()
	return true

func open_game_hud(tab: GameHUD.Tab = GameHUD.Tab.STATS) -> void:
	game_hud.show_hud(tab)

func close_game_hud() -> void:
	game_hud.hide_hud()

func set_hero_hud_visible(vis: bool) -> void:
	hero_hud.visible = vis

func start_dialogue(conversation: DialogueConversation, context: Dictionary[StringName, Variant] = {}) -> bool:
	if game_hud.is_open() or is_dialogue_open():
		return false
	return dialogue_runner.start(conversation, context)

func start_dialogue_sequence(sequence: DialogueSequence, context: Dictionary[StringName, Variant] = {}) -> bool:
	if game_hud.is_open() or is_dialogue_open():
		return false
	return dialogue_runner.start_sequence(sequence, context)

func update_dialogue_context(context: Dictionary[StringName, Variant]) -> void:
	dialogue_runner.update_context(context)

func is_dialogue_open() -> bool:
	return dialogue_runner.is_running() or reward_window.visible

func abort_dialogue() -> void:
	if dialogue_runner == null:
		return
	if dialogue_runner.is_running():
		dialogue_runner.abort()
		return
	if reward_window.visible:
		var interrupted_flow := _reward_flow
		_reward_flow = RewardFlow.NONE
		reward_window.close()
		match interrupted_flow:
			RewardFlow.DIALOGUE:
				_pending_quest_rewards.clear()
				dialogue_closed.emit(DialogueRunner.FinishReason.INTERRUPTED)
			RewardFlow.WORLD_CONTAINER:
				world_rewards_closed.emit()

func queue_acquisition_rewards(rewards: Array[RewardEntry]) -> void:
	acquisition_notification.enqueue(rewards)

func queue_quest_rewards(rewards: Array[RewardEntry]) -> void:
	_pending_quest_rewards = rewards.duplicate()

func _on_dialogue_started(_conversation: DialogueConversation) -> void:
	dialogue_window.open()
	_play_dialogue_sfx(dialogue_open_sfx_id)
	dialogue_opened.emit()

func _on_sequence_started(_sequence: DialogueSequence) -> void:
	dialogue_window.open()
	_play_dialogue_sfx(dialogue_open_sfx_id)
	dialogue_opened.emit()

func _on_dialogue_line_changed(entry: DialogueEntry, page_index: int) -> void:
	dialogue_window.show_line(entry, page_index)
	_play_dialogue_sfx(dialogue_advance_sfx_id)

func _on_dialogue_response_selected(_response: DialogueResponse) -> void:
	_play_dialogue_sfx(dialogue_response_sfx_id)

func _on_dialogue_finished(reason: DialogueRunner.FinishReason) -> void:
	dialogue_window.close()
	_play_dialogue_sfx(dialogue_close_sfx_id)
	if not _pending_quest_rewards.is_empty():
		_pending_finish_reason = reason
		_reward_flow = RewardFlow.DIALOGUE
		reward_window.show_rewards("Quest Complete!", _pending_quest_rewards)
		return
	dialogue_closed.emit(reason)

func _on_rewards_collected() -> void:
	var completed_flow := _reward_flow
	_reward_flow = RewardFlow.NONE
	match completed_flow:
		RewardFlow.DIALOGUE:
			_pending_quest_rewards.clear()
			dialogue_closed.emit(_pending_finish_reason)
		RewardFlow.WORLD_CONTAINER:
			world_rewards_closed.emit()

func _play_dialogue_sfx(sfx_id: StringName) -> void:
	if sfx_id.is_empty():
		return
	AudioManager.play_sfx_by_id(String(sfx_id))
