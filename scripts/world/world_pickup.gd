extends WorldLootSource
class_name WorldPickup
@export_group("Pickup Presentation")
@export var pickup_texture: Texture2D
@export var pickup_sfx_id: StringName = &""
@export var idle_animation: StringName = &"idle"
@export var collection_animation: StringName = &"collect"

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	super._ready()
	if not claim_finished.is_connected(_on_pickup_claim_finished):
		claim_finished.connect(_on_pickup_claim_finished)
	if pickup_texture != null:
		sprite.texture = pickup_texture
	if is_claimed():
		_hide_pickup()
	elif not idle_animation.is_empty() and animation_player.has_animation(idle_animation):
		animation_player.play(idle_animation)

func _hide_pickup() -> void:
	interact_area.set_enabled(false)
	visuals.hide()

func _on_pickup_claim_finished(result: ClaimResult, rewards: Array[RewardEntry]) -> void:
	if result != ClaimResult.CLAIMED:
		return
	_queue_acquisition_feedback(rewards)
	if not pickup_sfx_id.is_empty():
		AudioManager.play_sfx_by_id(pickup_sfx_id)
	if not collection_animation.is_empty() and animation_player.has_animation(collection_animation):
		animation_player.play(collection_animation)
		await animation_player.animation_finished
	_hide_pickup()

func _queue_acquisition_feedback(rewards: Array[RewardEntry]) -> void:
	var world_hud := ScreenManager.get_world_hud() as WorldHUD
	if world_hud != null:
		world_hud.queue_acquisition_rewards(rewards)
