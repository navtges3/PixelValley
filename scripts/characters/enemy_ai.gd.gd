extends RefCounted
class_name EnemyAI

# Chooses an ability and a valid target for a Monster's turn.
# Ability order matches the old behavior: conditional_abilities first, then basic_attack

const LOW_HP_RATIO := 0.5

class Decision:
	var ability: Ability
	var target: Combatant # null for SELF / PARTY / ENEMY_PARTY
	
	func _init(_ability: Ability, _target: Combatant = null) -> void:
		ability = _ability
		target = _target

var _rng := RandomNumberGenerator.new()

func _init(rng_seed: int = -1) -> void:
	if rng_seed >= 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()

func choose_action(actor: Monster, friendly: BattleParty, opposition: BattleParty) -> Decision:
	if actor == null or not actor.is_alive():
		return null
	var abilities: Array[Ability] = actor.conditional_abilities.duplicate()
	if actor.basic_attack != null:
		abilities.append(actor.basic_attack)
	for ability: Ability in abilities:
		var decision := _evaluate(ability, actor, friendly, opposition)
		if decision != null:
			return decision
	return null

func _evaluate(ability: Ability, actor: Monster, friendly: BattleParty, opposition: BattleParty) -> Decision:
	if ability == null or actor.current_nrg < ability.energy_cost:
		return null
	var valid := ability.get_valid_targets(actor, friendly, opposition)
	if valid.is_empty():
		return null
	match ability.target_type:
		Ability.TargetType.SELF, Ability.TargetType.PARTY, Ability.TargetType.ENEMY_PARTY:
			if ability.is_ready_for_targets(actor, valid):
				return Decision.new(ability)
		Ability.TargetType.ENEMY:
			var hostile := _pick_hostile_target(ability, actor, valid)
			if hostile != null:
				return Decision.new(ability, hostile)
		Ability.TargetType.ALLY:
			var ally := _pick_support_target(ability, actor, valid)
			if ally != null:
				return Decision.new(ability, ally)
	return null

func _pick_hostile_target(ability: Ability, actor: Monster, valid: Array[Combatant]) -> Combatant:
	var eligible := _filter_ready(ability, actor, valid)
	if eligible.is_empty():
		return null
	var wounded: Array[Combatant] = []
	for candidate: Combatant in eligible:
		if _hp_ratio(candidate) <= LOW_HP_RATIO:
			wounded.append(candidate)
	if not wounded.is_empty():
		return _lowest_hp_ratio(wounded)
	return eligible[_rng.randi_range(0, eligible.size() - 1)]

func _pick_support_target(ability: Ability, actor: Monster, valid: Array[Combatant]) -> Combatant:
	var injured: Array[Combatant] = []
	for candidate: Combatant in _filter_ready(ability, actor, valid):
		if candidate.current_hp < candidate.max_hp:
			injured.append(candidate)
	return _lowest_hp_ratio(injured) if not injured.is_empty() else null

# Per-target readiness, so a TARGET-subject Condition filters candidates individually.
func _filter_ready(ability: Ability, actor: Monster, candidates: Array[Combatant]) -> Array[Combatant]:
	var eligible: Array[Combatant] = []
	for candidate: Combatant in candidates:
		var single: Array[Combatant] = [candidate]
		if ability.is_ready_for_targets(actor, single):
			eligible.append(candidate)
	return eligible

# Strict < means ties resolve to party order, which keeps results deterministic.
func _lowest_hp_ratio(candidates: Array[Combatant]) -> Combatant:
	var best: Combatant = candidates[0]
	for candidate: Combatant in candidates:
		if _hp_ratio(candidate) < _hp_ratio(best):
			best = candidate
	return best

func _hp_ratio(combatant: Combatant) -> float:
	return float(combatant.current_hp) / float(maxi(combatant.max_hp, 1))
	
