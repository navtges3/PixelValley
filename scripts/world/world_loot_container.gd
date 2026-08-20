extends WorldLootSource
class_name WorldLootContainer

@export_group("Container Presentation")
@export var closed_texture: Texture2D
@export var opened_texture: Texture2D
@export var reward_title: String = "Found Items!"
@export var open_animation: StringName = &"open"
@export var open_sfx_id: StringName = &""

@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if not claim_finished.is_connected(_on_claim_finished):
		claim_finished.connect(_on_claim_finished)
	super._ready()
	_apply_opened_state(is_claimed())

func _on_claim_finished(result: ClaimResult, rewards: Array[RewardEntry]) -> void:
	if result != ClaimResult.CLAIMED:
		return
	_apply_opened_state(true)
	if not open_sfx_id.is_empty():
		AudioManager.play_sfx_by_id(open_sfx_id)
	if not open_animation.is_empty() and animation_player.has_animation(open_animation):
		animation_player.play(open_animation)
	var world_hud := ScreenManager.get_world_hud() as WorldHUD
	if world_hud != null:
		world_hud.show_world_rewards(reward_title, rewards)

func _apply_opened_state(opened: bool) -> void:
	var texture := opened_texture if opened else closed_texture
	if texture != null:
		sprite.texture = texture
