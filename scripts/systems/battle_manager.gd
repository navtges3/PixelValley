extends Node

enum BattleState { PLAYER_TURN, MONSTER_TURN, RESOLVING, VICTORY, DEFEAT }

var hero: Hero
var monster: Monster
var spawn_point_id: String = ""
var location_id: String = ""

var state = BattleState.PLAYER_TURN

signal new_monster(monster_ref: Monster)
signal player_turn()
signal monster_turn()
signal battle_won(entries: Array)
signal hero_defeated()

# UI updates
signal battle_log_updated(msg: String)
signal hero_updated(hero_ref: Hero)
signal monster_updated(monster_ref: Monster)

# Animation Signals
signal hero_attacking()
signal hero_hurt()
signal monster_attacking()
signal monster_hurt()

func setup_battle(config: Dictionary) -> void:
	hero = config.get("hero")
	spawn_point_id = config.get("spawn_point_id", "")
	location_id = config.get("location_id", "")
	var monster_id: MonsterLoader.MonsterID = config.get("monster_id", MonsterLoader.MonsterID.GOBLIN)
	monster = MonsterLoader.new_monster(monster_id)
	hero_updated.emit(hero)
	new_monster.emit(monster)
	battle_log_updated.emit("A %s aproaches!\n" % monster.get_colored_name())
	monster_updated.emit(monster)
	start_player_turn()

func start_player_turn() -> void:
	state = BattleState.PLAYER_TURN
	battle_log_updated.emit("%s's turn!\n" % hero.get_colored_name())
	player_turn.emit()

func get_hero_abilities() -> Array[Ability]:
	return hero.inventory.equipped_weapon.abilities

func player_ability_selected(ability: Ability) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	hero_attacking.emit()
	var output = ability.use(hero, monster)
	if output:
		battle_log_updated.emit(output)
		monster_hurt.emit()
		monster_updated.emit(monster)
		hero_updated.emit(hero)
		end_player_turn()

func get_hero_items() -> Dictionary:
	return hero.inventory.potions

func player_item_selected(item_id: String) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	var result := hero.use_item(item_id)
	battle_log_updated.emit(result)
	hero_updated.emit(hero)
	end_player_turn()

func meditate() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	if hero.rest_cooldown > 0:
		return
	hero.meditate()
	battle_log_updated.emit("%s meditates recovering health and energy.\n" % hero.get_colored_name())
	hero_updated.emit(hero)
	end_player_turn()

func end_player_turn() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	hero.update_cooldown()
	var effect_output := hero.process_active_effects()
	battle_log_updated.emit(effect_output)
	hero_updated.emit(hero)

	if monster.is_alive():
		state = BattleState.MONSTER_TURN
		monster_turn.emit()
		await get_tree().create_timer(0.5).timeout
		enemy_turn()
	else:
		_on_monster_killed()

func _on_monster_killed() -> void:
	var experience := monster.calculate_experience()
	var gold := monster.calculate_gold()
	var loot := monster.roll_loot(hero.hero_class)
	var entries: Array[RewardEntry] = []
	entries.append(RewardEntry.experience(experience))
	entries.append(RewardEntry.gold(gold))
	hero.gain_experience(experience)
	hero.inventory.gold += gold
	_collect_loot(loot, entries)
	hero_updated.emit(hero)
	GameState.monster_killed.emit(monster.monster_id, location_id)
	end_battle(true)

func _collect_loot(loot: Dictionary, entries: Array[RewardEntry]) -> void:
	for item_id in loot.get("potions", {}):
		var count: int = loot["potions"][item_id]
		hero.inventory.add_potion(item_id, count)
		entries.append(RewardEntry.potion(item_id, count))
	var weapon_id: String = loot.get("weapon_id", "")
	if weapon_id != "":
		if hero.inventory.has_weapon_in_stash(weapon_id):
			var weapon := ItemLoader.get_item(weapon_id) as Weapon
			var sold_gold := weapon.value if weapon else 0
			hero.inventory.gold += sold_gold
			entries.append(RewardEntry.weapon_sold(weapon_id, sold_gold))
		else:
			hero.inventory.add_weapon_to_stash(weapon_id)
			entries.append(RewardEntry.weapon(weapon_id))

func enemy_turn() -> void:
	battle_log_updated.emit("Enemy turn...\n")
	monster_attacking.emit()
	var monster_ability = monster.choose_ability(hero)
	var output = monster_ability.use(monster, hero)
	battle_log_updated.emit(output)
	hero_hurt.emit()
	hero_updated.emit(hero)
	end_enemy_turn()

func end_enemy_turn() -> void:
	monster.update_cooldown()
	var effect_output := monster.process_active_effects()
	battle_log_updated.emit(effect_output)
	monster_updated.emit(monster)
	if hero.is_alive():
		start_player_turn()
	else:
		end_battle(false)

func end_battle(player_won: bool, entries: Array[RewardEntry] = []) -> void:
	state = BattleState.VICTORY if player_won else BattleState.DEFEAT
	if player_won:
		if spawn_point_id != "":
			WorldManager.mark_spawner_defeated(location_id, spawn_point_id)
		battle_won.emit(entries)
	else:
		hero_defeated.emit()

func player_fled() -> void:
	pass
