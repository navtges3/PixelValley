extends Node
class_name BattleManager

enum BattleState { PLAYER_TURN, MONSTER_TURN, RESOLVING, VICTORY, DEFEAT }

var hero: Hero
var monster: Monster
var spawn_point_id: String = ""
var location_id: String = ""
var flee_position: Vector2 = Vector2.ZERO

var state: BattleState = BattleState.PLAYER_TURN

var _hero_effects_at_turn_start: Array[EffectManager.TurnEffectSnapshot] = []
var _monster_effects_at_turn_start: Array[EffectManager.TurnEffectSnapshot] = []

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

var effect_events := EffectEventDispatcher.new()
signal effect_lifecycle_changed(event: EffectLifecycleEvent)

func _init() -> void:
	effect_events.lifecycle_event.connect(_on_effect_lifecycle_event)

func _on_effect_lifecycle_event(event: EffectLifecycleEvent) -> void:
	effect_lifecycle_changed.emit(event)

func setup_battle(config: Dictionary) -> void:
	hero = config.get("hero")
	spawn_point_id = config.get("spawn_point_id", "")
	location_id = config.get("location_id", "")
	flee_position = config.get("flee_position", Vector2.ZERO)
	var monster_id: MonsterLoader.MonsterID = config.get("monster_id", MonsterLoader.MonsterID.GOBLIN)
	monster = MonsterLoader.new_monster(monster_id)
	hero_updated.emit(hero)
	new_monster.emit(monster)
	battle_log_updated.emit("A %s aproaches!\n" % monster.get_colored_name())
	monster_updated.emit(monster)
	start_player_turn()

func start_player_turn() -> void:
	_hero_effects_at_turn_start = EffectManager.capture_turn_start(hero)
	state = BattleState.PLAYER_TURN
	battle_log_updated.emit("%s's turn!\n" % hero.get_colored_name())
	player_turn.emit()

func get_hero_abilities() -> Array[Ability]:
	return hero.inventory.equipped_weapon.abilities

func player_ability_selected(ability: Ability) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	hero_attacking.emit()
	var output := ability.use(hero, monster, effect_events)
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
	var result := hero.use_item(item_id, effect_events)
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
	var effect_output := EffectManager.process_turn_end(hero, _hero_effects_at_turn_start, effect_events)
	if not effect_output.is_empty():
		battle_log_updated.emit(effect_output)
	hero_updated.emit(hero)
	if _resolve_deaths_after_effects():
		return
	state = BattleState.MONSTER_TURN
	_monster_effects_at_turn_start = EffectManager.capture_turn_start(monster)
	monster_turn.emit()
	await get_tree().create_timer(0.5).timeout
	enemy_turn()
	
func enemy_turn() -> void:
	battle_log_updated.emit("Enemy turn...\n")
	monster_attacking.emit()
	var monster_ability := monster.choose_ability(hero)
	var output := monster_ability.use(monster, hero, effect_events)
	battle_log_updated.emit(output)
	hero_hurt.emit()
	hero_updated.emit(hero)
	end_enemy_turn()

func end_enemy_turn() -> void:
	monster.update_cooldown()
	var effect_output := EffectManager.process_turn_end(monster, _monster_effects_at_turn_start, effect_events)
	if not effect_output.is_empty():
		battle_log_updated.emit(effect_output)
	monster_updated.emit(monster)
	if _resolve_deaths_after_effects():
		return
	start_player_turn()

func end_battle(player_won: bool, entries: Array[RewardEntry] = []) -> void:
	if state in [BattleState.VICTORY, BattleState.DEFEAT]:
		return
	state = BattleState.VICTORY if player_won else BattleState.DEFEAT
	var cleanup_output := _cleanup_battle_effects()
	if not cleanup_output.is_empty():
		battle_log_updated.emit(cleanup_output)
	if player_won:
		if spawn_point_id != "":
			WorldManager.mark_spawner_defeated(location_id, spawn_point_id)
		battle_won.emit(entries)
	else:
		hero_defeated.emit()

func player_fled() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	state = BattleState.RESOLVING
	var cleanup_output := _cleanup_battle_effects()
	if not cleanup_output.is_empty():
		battle_log_updated.emit(cleanup_output)
	if flee_position != Vector2.ZERO:
		GameState.pre_combat_position = flee_position

func _cleanup_battle_effects() -> String:
	var output := EffectManager.cleanup_after_battle(hero, false, effect_events)
	output += EffectManager.cleanup_after_battle(monster, true, effect_events)
	_hero_effects_at_turn_start.clear()
	_monster_effects_at_turn_start.clear()
	hero_updated.emit(hero)
	monster_updated.emit(monster)
	return output

func _resolve_deaths_after_effects() -> bool:
	if not hero.is_alive():
		end_battle(false)
		return true
	if not monster.is_alive():
		_on_monster_killed()
		return true
	return false

func _on_monster_killed() -> void:
	if state in [
		BattleState.RESOLVING,
		BattleState.VICTORY,
		BattleState.DEFEAT,
	]:
		return
	state = BattleState.RESOLVING
	var entries: Array[RewardEntry] = _grant_victory_rewards()
	hero_updated.emit(hero)
	var event := MonsterKilledEvent.new(monster.monster_id, location_id)
	GameState.gameplay_event.emit(event)
	end_battle(true, entries)

func _grant_victory_rewards() -> Array[RewardEntry]:
	var entries: Array[RewardEntry] = []
	var experience_entry := RewardService.grant_experience(hero, monster.calculate_experience())
	if experience_entry != null:
		entries.append(experience_entry)
	var gold_entry := RewardService.grant_gold(hero, monster.calculate_gold())
	if gold_entry != null:
		entries.append(gold_entry)
	entries.append_array(RewardService.grant_loot(monster.roll_loot(), hero))
	return entries
