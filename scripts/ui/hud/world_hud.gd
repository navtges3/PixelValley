extends CanvasLayer
class_name WorldHUD

signal dialogue_opened
signal dialogue_closed(reason: DialogueRunner.FinishReason)
signal dialogue_action_requested(action: DialogueAction, context: Dictionary[StringName, Variant])

@onready var game_hud: GameHUD = $GameHud
@onready var hero_hud: HeroHUD = $HeroHUD
@onready var tracked_quest_hud: TrackedQuestHUD = $TrackedQuestHUD

@onready var dialogue_window: DialogueWindow = $DialogueLayer/DialogueWindow
@onready var reward_window: RewardWindow = $RewardLayer/RewardWindow
var dialogue_runner: DialogueRunner
var _pending_quest_rewards: Array[RewardEntry] = []
var _pending_finish_reason: DialogueRunner.FinishReason = DialogueRunner.FinishReason.COMPLETED

func _ready() -> void:
	dialogue_runner = DialogueRunner.new()
	dialogue_runner.conversation_started.connect(_on_conversation_started)
	dialogue_runner.line_changed.connect(dialogue_window.show_line)
	dialogue_runner.responses_changed.connect(dialogue_window.show_responses)
	dialogue_runner.action_requested.connect(dialogue_action_requested.emit)
	dialogue_runner.conversation_finished.connect(_on_conversation_finished)
	dialogue_window.advance_requested.connect(dialogue_runner.advance)
	dialogue_window.response_requested.connect(dialogue_runner.choose_response)
	dialogue_window.cancel_requested.connect(dialogue_runner.cancel)
	reward_window.rewards_collected.connect(_on_rewards_collected)
	dialogue_window.close()
	reward_window.hide()

func hide_all() -> void:
	abort_dialogue()
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

func update_dialogue_context(
	context: Dictionary[StringName, Variant]
) -> void:
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
		reward_window.hide()
		_pending_quest_rewards.clear()
		dialogue_closed.emit(DialogueRunner.FinishReason.INTERRUPTED)

func queue_quest_rewards(rewards: Array[RewardEntry]) -> void:
	_pending_quest_rewards = rewards.duplicate()

func _on_conversation_started(_conversation: DialogueConversation) -> void:
	dialogue_window.open()
	dialogue_opened.emit()

func _on_conversation_finished(reason: DialogueRunner.FinishReason) -> void:
	dialogue_window.close()
	if not _pending_quest_rewards.is_empty():
		_pending_finish_reason = reason
		reward_window.show_rewards(
			"Quest Complete!",
			_pending_quest_rewards
		)
		return
	dialogue_closed.emit(reason)

func _on_rewards_collected() -> void:
	_pending_quest_rewards.clear()
	dialogue_closed.emit(_pending_finish_reason)
