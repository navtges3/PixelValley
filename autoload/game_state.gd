extends Node

const SAVE_DIR := "user://saves"

var hero: Hero = null
var village: Village = null
var quest_manager: QuestManager = null
var dialogue_state: DialogueState = DialogueState.new()
var pre_combat_position: Vector2 = Vector2.ZERO

var player_location: Dictionary = {
	"scene": ScreenManager.ScreenName.VALLEY,
	"entrance_id": ""
}

@warning_ignore("unused_signal")
signal gameplay_event(event: GameplayEvent)
signal quest_manager_changed(manager: QuestManager)

func start_new_game(slot: int = 1) -> void:
	dialogue_state.clear()
	_setup_hero_inv()
	_setup_village()
	var new_manager := QuestManager.new()
	new_manager.new_game()
	set_quest_manager(new_manager)
	pre_combat_position = Vector2.ZERO
	WorldManager.reset()
	SaveManager.new_save(slot)

func reset_state() -> void:
	dialogue_state.clear()
	set_quest_manager(null)
	hero = null
	village = null
	pre_combat_position = Vector2.ZERO
	player_location = {
		"scene": ScreenManager.ScreenName.VALLEY,
		"entrance_id": ""
	}

func set_player_location(scene: ScreenManager.ScreenName, entrance_id: String = "") -> void:
	player_location["scene"] = scene
	player_location["entrance_id"] = entrance_id

func set_quest_manager(new_manager: QuestManager) -> void:
	if quest_manager == new_manager:
		return
	if quest_manager != null:
		quest_manager.disconnect_signals()
	quest_manager = new_manager
	quest_manager_changed.emit(quest_manager)

func _setup_village() -> void:
	village = Village.new()
	village.name = "Lexiton"
	village.inn = Inn.new()
	village.inn.name = "Crooked Tusk"
	_setup_potion_shop()
	_setup_weapon_shop()

func _setup_potion_shop() -> void:
	var shop := Shop.new()
	shop.name = "Willowroot Remedies"
	shop.add_item("lesser_healing_potion", 5)
	shop.add_item("greater_healing_potion", 3)
	shop.add_item("attack_potion", 3)
	shop.add_item("magic_potion", 3)
	shop.add_item("defense_potion", 3)
	shop.add_item("resist_potion", 3)
	shop.add_item("energy_potion", 3)
	village.potion_shop = shop

func _setup_weapon_shop() -> void:
	var shop := Shop.new()
	shop.name = "Oakshield Forge"
	var common_weapons: Array = WeaponDatabase.CLASS_WEAPON_TABLE.get(hero.hero_class, {}).get(Item.Rarity.COMMON, [])
	for weapon_id in common_weapons:
		shop.add_item(weapon_id, 1)
	village.weapon_shop = shop

func _setup_hero_inv() -> void:
	hero.inventory.potions.clear()
	hero.inventory.add_potion("lesser_healing_potion", 3)
	hero.inventory.add_potion("attack_potion", 3)
	hero.inventory.add_potion("defense_potion", 3)
	hero.inventory.add_potion("energy_potion", 3)
