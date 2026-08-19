extends Node2D
class_name WorldLootSource

enum ClaimResult {
	CLAIMED,
	ALREADY_CLAIMED,
	INVALID_CONFIGURATION,
	NO_RECIPIENT,
	IN_PROGRESS,
}

const GROUP_NAME: StringName = &"world_loot_source"

signal claim_finished(result: ClaimResult, rewards: Array[RewardEntry])

@export var location_id: String = ""
@export var loot_source_id: String = ""
@export var loot_table: DropTable

@onready var interact_area: InteractArea = $InteractArea

var _claim_in_progress: bool = false

func _enter_tree() -> void:
	add_to_group(GROUP_NAME)

func _ready() -> void:
	if not interact_area.interacted.is_connected(_on_interacted):
		interact_area.interacted.connect(_on_interacted)
	var errors := get_validation_errors()
	for error: String in errors:
		push_error(error)
	if not errors.is_empty():
		interact_area.set_enabled(false)
		return
	_restore_claimed_state()

func is_claimed() -> bool:
	return WorldManager.is_loot_claimed(location_id, loot_source_id)

func try_claim(recipient: Hero) -> ClaimResult:
	var empty_rewards: Array[RewardEntry] = []
	if _claim_in_progress:
		return ClaimResult.IN_PROGRESS
	if not get_validation_errors().is_empty():
		interact_area.set_enabled(false)
		claim_finished.emit(ClaimResult.INVALID_CONFIGURATION, empty_rewards)
		return ClaimResult.INVALID_CONFIGURATION
	if recipient == null:
		claim_finished.emit(ClaimResult.NO_RECIPIENT, empty_rewards)
		return ClaimResult.NO_RECIPIENT
	if is_claimed():
		interact_area.set_enabled(false)
		claim_finished.emit(ClaimResult.ALREADY_CLAIMED, empty_rewards)
		return ClaimResult.ALREADY_CLAIMED
	_claim_in_progress = true
	var loot: Dictionary = loot_table.roll()
	var rewards := RewardService.grant_loot(loot, recipient)
	WorldManager.mark_loot_claimed(location_id, loot_source_id)
	interact_area.set_enabled(false)
	_autosave_after_claim()
	_claim_in_progress = false
	claim_finished.emit(ClaimResult.CLAIMED, rewards)
	return ClaimResult.CLAIMED

func get_validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if location_id.is_empty():
		errors.append("WorldLootSource '%s' has an empty location ID." % get_path())
	if loot_source_id.is_empty():
		errors.append("WorldLootSource '%s' has an empty loot-source ID." % get_path())
	if loot_table == null:
		errors.append("WorldLootSource '%s' has no loot table." % get_path())
	if not location_id.is_empty() and not loot_source_id.is_empty():
		for node: Node in get_tree().get_nodes_in_group(GROUP_NAME):
			var other := node as WorldLootSource
			if other == null or other == self:
				continue
			if (other.location_id == location_id and other.loot_source_id == loot_source_id):
				errors.append(
					"Duplicate world-loot ID '%s' in location '%s': '%s' and '%s'."
					% [loot_source_id, location_id, get_path(), other.get_path()]
				)
				break
	return errors

func _autosave_after_claim() -> void:
	SaveManager.save_hero()
	SaveManager.save_world_state()

func _on_interacted() -> void:
	try_claim(GameState.hero)

func _restore_claimed_state() -> void:
	interact_area.set_enabled(not is_claimed())
