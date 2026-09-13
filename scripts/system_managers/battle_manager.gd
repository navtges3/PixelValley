extends Node
class_name BattleManager

enum BattleState { PLAYER_TURN, MONSTER_TURN, RESOLVING, VICTORY, DEFEAT }

var player_party := BattleParty.new()
var enemy_party := BattleParty.new()

var active_combatant: Combatant
var _turn_order: Array[Combatant] = []
var _turn_index := -1
var _active_effects_at_turn_start: Array[EffectManager.TurnEffectSnapshot] = []
var _defeated_combatants: Array[Combatant] = []

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

signal combatant_updated(combatant: Combatant)
signal combatant_attacking(combatant: Combatant)
signal combatant_hurt(combatant: Combatant)
signal combatant_defeated(combatant: Combatant)

var effect_events := EffectEventDispatcher.new()
signal effect_lifecycle_changed(event: EffectLifecycleEvent)

func _init() -> void:
	effect_events.lifecycle_event.connect(_on_effect_lifecycle_event)

func _on_effect_lifecycle_event(event: EffectLifecycleEvent) -> void:
	effect_lifecycle_changed.emit(event)

func setup_battle(config: Dictionary) -> void:
	spawn_point_id = config.get("spawn_point_id", "")
	location_id = config.get("location_id", "")
	flee_position = config.get("flee_position", Vector2.ZERO)
	var configured_players := config.get("player_party") as BattleParty
	var configured_enemies := config.get("enemy_party") as BattleParty
	player_party = configured_players if configured_players != null else BattleParty.new()
	enemy_party = configured_enemies if configured_enemies != null else BattleParty.new()
	_defeated_combatants.clear()
	if player_party.get_members().is_empty():
		var configured_hero := config.get("hero") as Hero
		if configured_hero != null:
			player_party.add_member(configured_hero)
	if enemy_party.get_members().is_empty():
		var monster_id: MonsterLoader.MonsterID = (
			config.get("monster_id", MonsterLoader.MonsterID.GOBLIN))
		enemy_party.add_member(MonsterLoader.new_monster(monster_id))
	var players := player_party.get_members()
	var enemies := enemy_party.get_members()
	hero = players[0] as Hero if not players.is_empty() else null
	monster = enemies[0] as Monster if not enemies.is_empty() else null
	if hero == null or monster == null:
		push_warning("BattleManager: a battle requires at least one hero and one monster.")
		return
	hero_updated.emit(hero)
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
	if _is_player_combatant(active_combatant):
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
	var actor := active_combatant as Monster
	var target := _get_first_living_player()
	if actor == null or target == null:
		return
	combatant_attacking.emit(actor)
	var ability := actor.choose_ability(target)
	var output := ability.use(actor, target, effect_events)
	battle_log_updated.emit(output)
	combatant_hurt.emit(target)
	_emit_combatant_updated(actor)
	_emit_combatant_updated(target)
	_emit_newly_defeated_combatants()
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
	_emit_newly_defeated_combatants()
	if _resolve_party_defeat():
		return
	_start_next_turn()

func _update_active_combatant_cooldowns() -> void:
	if active_combatant is Hero:
		(active_combatant as Hero).update_cooldown()
	elif active_combatant is Monster:
		(active_combatant as Monster).update_cooldown()

func _emit_combatant_updated(combatant: Combatant) -> void:
	if combatant != null:
		combatant_updated.emit(combatant)
		if combatant == hero:
			hero_updated.emit(hero)
		elif combatant == monster:
			monster_updated.emit(monster)

func _emit_newly_defeated_combatants() -> void:
	for combatant: Combatant in player_party.get_members():
		_emit_combatant_defeated_if_needed(combatant)
	for combatant: Combatant in enemy_party.get_members():
		_emit_combatant_defeated_if_needed(combatant)

func _emit_combatant_defeated_if_needed(combatant: Combatant) -> void:
	if combatant.is_alive() or _defeated_combatants.has(combatant):
		return
	_defeated_combatants.append(combatant)
	combatant_defeated.emit(combatant)

func _resolve_party_defeat() -> bool:
	if not player_party.has_living_members():
		end_battle(false)
		return true
	if not enemy_party.has_living_members():
		_on_enemy_party_defeated()
		return true
	return false

func _on_enemy_party_defeated() -> void:
	if state in [
		BattleState.RESOLVING,
		BattleState.VICTORY,
		BattleState.DEFEAT,
	]:
		return
	state = BattleState.RESOLVING
	for combatant: Combatant in enemy_party.get_members():
		var enemy := combatant as Monster
		if enemy != null:
			GameState.gameplay_event.emit(
				MonsterKilledEvent.new(enemy.monster_id, location_id))
	var entries := _grant_victory_rewards()
	end_battle(true, entries)

func get_hero_abilities() -> Array[Ability]:
	var actor := active_combatant as Hero
	return actor.inventory.equipped_weapon.abilities if actor != null else []

func player_ability_selected(ability: Ability) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	var actor := active_combatant as Hero
	var target := _get_first_living_enemy()
	if actor == null or target == null:
		return
	combatant_attacking.emit(actor)
	var output := ability.use(actor, target, effect_events)
	if output.is_empty():
		return
	battle_log_updated.emit(output)
	combatant_hurt.emit(target)
	_emit_combatant_updated(actor)
	_emit_combatant_updated(target)
	_emit_newly_defeated_combatants()
	_complete_active_turn()

func get_hero_items() -> Dictionary:
	return get_active_hero_items()

func get_active_hero_items() -> Dictionary:
	var actor := active_combatant as Hero
	return actor.inventory.potions if actor != null else {}

func player_item_selected(item_id: String) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	var actor := active_combatant as Hero
	if actor == null:
		return
	var result := actor.use_item(item_id, effect_events)
	battle_log_updated.emit(result)
	_emit_combatant_updated(actor)
	_complete_active_turn()

func meditate() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	var actor := active_combatant as Hero
	if actor == null or actor.rest_cooldown > 0:
		return
	actor.meditate()
	battle_log_updated.emit("%s meditates recovering health and energy.\n"
		% actor.get_colored_name())
	_emit_combatant_updated(actor)
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
	for combatant: Combatant in player_party.get_members():
		_emit_combatant_updated(combatant)
	for combatant: Combatant in enemy_party.get_members():
		_emit_combatant_updated(combatant)
	return output

func _grant_victory_rewards() -> Array[RewardEntry]:
	var entries: Array[RewardEntry] = []
	var recipient := _get_reward_recipient()
	if recipient == null:
		return entries
	for combatant: Combatant in enemy_party.get_members():
		var enemy := combatant as Monster
		if enemy == null:
			continue
		var experience := RewardService.grant_experience(
			recipient, enemy.calculate_experience())
		if experience != null:
			entries.append(experience)
		var gold := RewardService.grant_gold(
			recipient, enemy.calculate_gold())
		if gold != null:
			entries.append(gold)
		entries.append_array(RewardService.grant_loot(enemy.roll_loot(), recipient))
	return entries

func _is_player_combatant(combatant: Combatant) -> bool:
	return player_party.has_member(combatant)

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
	var players := player_party.get_alive_members()
	return players[0] if not players.is_empty() else null

func _get_reward_recipient() -> Hero:
	var players := player_party.get_members()
	for member: Combatant in players:
		if member is Hero:
			return member as Hero
	return null

class TurnOrderEntry:
	var combatant: Combatant
	var is_player_side: bool
	var party_index: int

	func _init(_combatant: Combatant, _is_player_side: bool, _party_index: int) -> void:
		combatant = _combatant
		is_player_side = _is_player_side
		party_index = _party_index
