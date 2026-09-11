extends Node
class_name BattleManager

enum BattleState { PLAYER_TURN, MONSTER_TURN, RESOLVING, VICTORY, DEFEAT }

var player_party := BattleParty.new()
var enemy_party := BattleParty.new()

var active_combatant: Combatant
var _turn_order: Array[Combatant] = []
var _turn_index := -1
var _active_effects_at_turn_start: Array[EffectManager.TurnEffectSnapshot] = []

signal active_combatant_changed(combatant: Combatant)

var hero: Hero
var monster: Monster
var spawn_point_id: String = ""
var location_id: String = ""
var flee_position: Vector2 = Vector2.ZERO

var state: BattleState = BattleState.PLAYER_TURN

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
	var configured_player_party := config.get("player_party") as BattleParty
	var configured_enemy_party := config.get("enemy_party") as BattleParty
	player_party = configured_player_party if configured_player_party != null else BattleParty.new()
	enemy_party = configured_enemy_party if configured_enemy_party != null else BattleParty.new()
	if not player_party.has_member(hero):
		player_party.add_member(hero)
	if not enemy_party.has_member(monster):
		enemy_party.add_member(monster)
	hero_updated.emit(hero)
	new_monster.emit(monster)
	battle_log_updated.emit("A %s aproaches!\n" % monster.get_colored_name())
	monster_updated.emit(monster)
	_build_turn_order()
	_start_next_turn()

func _build_turn_order() -> void:
	var entries: Array[TurnOrderEntry] = []
	var living_players := player_party.get_alive_members()
	for index: int in living_players.size():
		entries.append(TurnOrderEntry.new(living_players[index], true, index))
	var living_enemies := enemy_party.get_alive_members()
	for index: int in living_enemies.size():
		entries.append(TurnOrderEntry.new(living_enemies[index], false, index))
	entries.sort_custom(_sort_turn_entries)
	_turn_order.clear()
	for entry: TurnOrderEntry in entries:
		_turn_order.append(entry.combatant)
	_turn_index = -1

func _sort_turn_entries(a: TurnOrderEntry, b: TurnOrderEntry) -> bool:
	if a.combatant.initiative != b.combatant.initiative:
		return a.combatant.initiative > b.combatant.initiative
	# On an initiative tie, the player side acts first
	if a.is_player_side != b.is_player_side:
		return a.is_player_side
	# Same faction + same Initiative: preserve BattlePraty membership order
	return a.party_index < b.party_index

func _start_next_turn() -> void:
	if _resolve_party_defeat():
		return
	var next_combatant := _get_next_living_combatant()
	if next_combatant == null:
		push_warning("BattleManager: no living combatant is available.")
		return
	active_combatant = next_combatant
	_active_effects_at_turn_start = EffectManager.capture_turn_start(active_combatant)
	active_combatant_changed.emit(active_combatant)
	battle_log_updated.emit("%s's turn!\n" % active_combatant.get_colored_name())
	if player_party.has_member(active_combatant):
		state = BattleState.PLAYER_TURN
		player_turn.emit()
	else:
		state = BattleState.MONSTER_TURN
		monster_turn.emit()
		_run_enemy_turn.call_deferred()

func _get_next_living_combatant() -> Combatant:
	if _turn_order.is_empty():
		return null
	for _attempt: int in _turn_order.size():
		_turn_index = (_turn_index + 1) % _turn_order.size()
		var candidate := _turn_order[_turn_index]
		if candidate.is_alive():
			return candidate
	return null

func _run_enemy_turn() -> void:
	await get_tree().create_timer(0.5).timeout
	if state != BattleState.MONSTER_TURN:
		return
	var acting_monster := _get_active_monster()
	var target := _get_first_living_player()
	if acting_monster == null or target == null:
		return
	battle_log_updated.emit("Enemy turn...\n")
	if acting_monster == monster:
		monster_attacking.emit()
	var ability := acting_monster.choose_ability(target)
	var output := ability.use(acting_monster, target, effect_events)
	battle_log_updated.emit(output)
	if target == hero:
		hero_hurt.emit()
	_emit_combatant_updated(target)
	_complete_active_turn()

func _complete_active_turn() -> void:
	if active_combatant == null:
		return
	if state in [BattleState.RESOLVING, BattleState.VICTORY, BattleState.DEFEAT]:
		return
	_update_active_combatant_cooldowns()
	var effect_output := EffectManager.process_turn_end(
		active_combatant, _active_effects_at_turn_start, effect_events)
	if not effect_output.is_empty():
		battle_log_updated.emit(effect_output)
	_emit_combatant_updated(active_combatant)
	if _resolve_party_defeat():
		return
	_start_next_turn()

func _update_active_combatant_cooldowns() -> void:
	if active_combatant is Hero:
		(active_combatant as Hero).update_cooldown()
	elif active_combatant is Monster:
		(active_combatant as Monster).update_cooldown()

func _emit_combatant_updated(combatant: Combatant) -> void:
	if combatant == hero:
		hero_updated.emit(hero)
	elif combatant == monster:
		monster_updated.emit(monster)

func _resolve_party_defeat() -> bool:
	if not player_party.has_living_members():
		end_battle(false)
		return true
	if not enemy_party.has_living_members():
		_on_monster_killed()
		return true
	return false

func get_hero_abilities() -> Array[Ability]:
	var acting_hero := _get_active_hero()
	return acting_hero.inventory.equipped_weapon.abilities if acting_hero != null else []

func player_ability_selected(ability: Ability) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	var acting_hero := _get_active_hero()
	var target := _get_first_living_enemy()
	if acting_hero == null or target == null:
		return
	# The current UI only has a visual for the primary hero.
	if acting_hero == hero:
		hero_attacking.emit()
	var output := ability.use(acting_hero, target, effect_events)
	if output.is_empty():
		return
	battle_log_updated.emit(output)
	# The current UI only has a visual/health bar for the primary monster.
	if target == monster:
		monster_hurt.emit()
		monster_updated.emit(monster)
	_emit_combatant_updated(acting_hero)
	_complete_active_turn()

func get_hero_items() -> Dictionary:
	var acting_hero := _get_active_hero()
	return acting_hero.inventory.potions if acting_hero != null else {}

func player_item_selected(item_id: String) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	var acting_hero := _get_active_hero()
	if acting_hero == null:
		return
	var result := acting_hero.use_item(item_id, effect_events)
	battle_log_updated.emit(result)
	_emit_combatant_updated(acting_hero)
	_complete_active_turn()

func meditate() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	var acting_hero := _get_active_hero()
	if acting_hero == null or acting_hero.rest_cooldown > 0:
		return
	acting_hero.meditate()
	battle_log_updated.emit("%s meditates recovering health and energy.\n"
		% acting_hero.get_colored_name())
	_emit_combatant_updated(acting_hero)
	_complete_active_turn()

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
	var output := ""
	for combatant: Combatant in player_party.get_members():
		output += EffectManager.cleanup_after_battle(
			combatant, false, effect_events)
	for combatant: Combatant in enemy_party.get_members():
		output += EffectManager.cleanup_after_battle(
			combatant, true, effect_events)
	_active_effects_at_turn_start.clear()
	active_combatant = null
	hero_updated.emit(hero)
	monster_updated.emit(monster)
	return output

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

func _get_active_hero() -> Hero:
	if active_combatant is Hero:
		return active_combatant as Hero
	return null

func _get_active_monster() -> Monster:
	if active_combatant is Monster:
		return active_combatant as Monster
	return null

func _get_first_living_enemy() -> Combatant:
	var enemies := enemy_party.get_alive_members()
	return enemies[0] if not enemies.is_empty() else null

func _get_first_living_player() -> Combatant:
	var heroes := player_party.get_alive_members()
	return heroes[0] if not heroes.is_empty() else null

class TurnOrderEntry:
	var combatant: Combatant
	var is_player_side: bool
	var party_index: int

	func _init(_combatant: Combatant, _is_player_side: bool, _party_index: int) -> void:
		combatant = _combatant
		is_player_side = _is_player_side
		party_index = _party_index
