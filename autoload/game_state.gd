extends Node

const SAVE_DIR := "user://saves"
const DEFAULT_VILLAGE = preload("res://resources/villages/default_village.tres")

var hero: Hero = null
var village: Village = null
var current_quest: Quest = null
var quest_manager: QuestManager = null
var pre_combat_position: Vector2 = Vector2.ZERO

var player_location: Dictionary = {
	"scene": ScreenManager.ScreenName.VALLEY,
	"entrance_id": ""
}

@warning_ignore("unused_signal")
signal monster_killed(monster_id: MonsterLoader.MonsterID, location_id: String)
signal quest_manager_ready

# --- Game Start Flow ---
func start_new_game(slot := 1) -> void:
	_setup_hero_inv()
	village = DEFAULT_VILLAGE.duplicate()
	_setup_default_shop(village.shop)
	quest_manager = QuestManager.new()
	pre_combat_position = Vector2.ZERO
	quest_manager.new_game()
	WorldManager.reset()
	SaveManager.new_save(slot)
	quest_manager_ready.emit()
	print("GameState: New game started in slot %d" % slot)

func _setup_default_shop(shop: Shop) -> void:
	shop.inventory.clear()
	shop.add_item("lesser_healing_potion", 5)
	shop.add_item("greater_healing_potion", 3)
	shop.add_item("attack_potion", 3)
	shop.add_item("magic_potion", 3)
	shop.add_item("defense_potion", 3)
	shop.add_item("resistance_potion", 3)
	shop.add_item("energy_potion", 3)

func _setup_hero_inv() -> void:
	hero.inventory.potions.clear()
	hero.inventory.add_potion("lesser_healing_potion", 3)
	hero.inventory.add_potion("attack_potion", 3)
	hero.inventory.add_potion("defense_potion", 3)
	hero.inventory.add_potion("energy_potion", 3)

func reset_state() -> void:
	hero = null
	village = null
	current_quest = null
	quest_manager = null

func set_player_location(scene: ScreenManager.ScreenName, entrance_id: String = "") -> void:
	print("Scene: %s, Entrance: %s" % [scene, entrance_id])
	player_location["scene"] = scene
	player_location["entrance_id"] = entrance_id
