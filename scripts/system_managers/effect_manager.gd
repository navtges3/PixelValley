extends RefCounted
class_name EffectManager

enum ApplicationStatus { ADDED, REFRESHED, UPGRADED, REJECTED_WEAKER }

class ApplicationResult:
	var status: ApplicationStatus
	var active_effect: ActiveEffect
	var previous_level: int = 0
	var incoming_level: int = 0
	var output: String = ""
	
	func _init(_status: ApplicationStatus, _active_effect:ActiveEffect,
		_incoming_level: int, _previous_level: int = 0, _output: String = "") -> void:
			status = _status
			active_effect = _active_effect
			incoming_level = _incoming_level
			previous_level = _previous_level
			output = _output

class TurnEffectSnapshot:
	var active_effect: ActiveEffect
	var lifecycle_revision: int

	func _init(_active_effect: ActiveEffect, _lifecycle_revision: int) -> void:
		active_effect = _active_effect
		lifecycle_revision = _lifecycle_revision

static func apply_effect(effect: Effect, source: Combatant, target: Combatant, remaining_turns: int = 0, dispatcher: EffectEventDispatcher = null) -> ApplicationResult:
	assert(effect != null, "Cannot apply a null Effect.")
	assert(target != null, "Cannot apply an Effect to a null target.")
	assert(effect.effect_id != &"", 'Effect "%s" must have a non-empty effect_id.' % effect.effect_name)
	
	var active_effect := find_active_effect(target, effect.effect_id)
	if active_effect == null:
		return _add_effect(effect, source, target, remaining_turns, dispatcher)
	if effect.level < active_effect.effect.level:
		return _reject_weaker_effect(effect, target, active_effect, dispatcher)
	if effect.level == active_effect.effect.level:
		return _refresh_effect(effect, source, target, active_effect, remaining_turns, dispatcher)
	return _upgrade_effect(effect, source, target, active_effect, remaining_turns, dispatcher)

static func find_active_effect(target: Combatant, effect_id: StringName) -> ActiveEffect:
	if target == null or effect_id == &"":
		return null
	for active_effect in target.active_effects:
		if active_effect == null or active_effect.effect == null:
			continue
		if active_effect.effect.effect_id == effect_id:
			return active_effect
	return null

static func has_effect(target: Combatant, effect_id: StringName) -> bool:
	return find_active_effect(target, effect_id) != null

static func get_active_effects(target: Combatant) -> Array[EffectView]:
	var views: Array[EffectView] = []
	if target == null:
		return views
	for active_effect: ActiveEffect in target.active_effects:
		if active_effect == null or active_effect.effect == null:
			continue
		views.append(EffectView.new(active_effect))
	return views

static func get_effect_remaining_turns(target: Combatant, effect_id: StringName) -> int:
	var active_effect := find_active_effect(target, effect_id)
	if active_effect == null:
		return 0
	return active_effect.remaining_turns

static func validate_unique_effect_ids(effects: Array[Effect]) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_effect_levels: Dictionary[StringName, Dictionary] = {}
	for effect: Effect in effects:
		if effect == null:
			continue
		if effect.effect_id == &"":
			errors.append('Effect "%s" has an empty effect_id.' % effect.effect_name)
			continue
		if not seen_effect_levels.has(effect.effect_id):
			seen_effect_levels[effect.effect_id] = {}
		var levels: Dictionary = seen_effect_levels[effect.effect_id]
		if levels.has(effect.level):
			var first_effect: Effect = levels[effect.level]
			errors.append(
				'Duplicate effect_id "%s" at level %d used by "%s" and "%s".' % [
					effect.effect_id,
					effect.level,
					first_effect.effect_name,
					effect.effect_name,
				]
			)
			continue
		levels[effect.level] = effect
	return errors

static func capture_turn_start(combatant: Combatant) -> Array[TurnEffectSnapshot]:
	var snapshot: Array[TurnEffectSnapshot] = []
	if combatant == null:
		return snapshot
	for active_effect: ActiveEffect in _get_active_effect_instances(combatant):
		snapshot.append(TurnEffectSnapshot.new(active_effect, active_effect.lifecycle_revision))
	return snapshot

static func process_turn_end(combatant: Combatant, effects_at_turn_start: Array[TurnEffectSnapshot], dispatcher: EffectEventDispatcher = null) -> String:
	if combatant == null:
		return ""
	var output := ""
	for snapshot: TurnEffectSnapshot in effects_at_turn_start:
		if snapshot == null:
			continue
		var active_effect := snapshot.active_effect
		if active_effect == null:
			continue
		if active_effect not in combatant.active_effects:
			continue
		if active_effect.target != combatant:
			continue
		if active_effect.lifecycle_revision != snapshot.lifecycle_revision:
			continue
		output += active_effect.apply_tick()
		active_effect.remaining_turns -= 1
		_dispatch(dispatcher, EffectLifecycleEvent.new(EffectLifecycleEvent.EventType.TICKED, active_effect))
		if active_effect.remaining_turns <= 0:
			output += remove_effect(active_effect, ActiveEffect.RemovalReason.NATURAL, dispatcher)
	return output

static func remove_effect(active_effect: ActiveEffect, reason: ActiveEffect.RemovalReason, dispatcher: EffectEventDispatcher = null) -> String:
	return _remove_effect_instance(active_effect, reason, dispatcher, true)

static func remove_effect_by_id(combatant: Combatant, effect_id: StringName, reason: ActiveEffect.RemovalReason = ActiveEffect.RemovalReason.CLEANSED, dispatcher: EffectEventDispatcher = null) -> String:
	var active_effect := find_active_effect(combatant, effect_id)
	if active_effect == null:
		return ""
	return remove_effect(active_effect, reason, dispatcher)

static func remove_all_effects(combatant: Combatant, reason: ActiveEffect.RemovalReason, include_persistent: bool = false, dispatcher: EffectEventDispatcher = null) -> String:
	if combatant == null:
		return ""
	var output := ""
	for active_effect: ActiveEffect in _get_active_effect_instances(combatant):
		if not include_persistent and active_effect.effect.persistence == Effect.Persistence.PERSISTENT:
			continue
		output += remove_effect(active_effect, reason, dispatcher)
	return output

static func cleanup_after_battle(combatant: Combatant, include_persistent: bool = false, dispatcher: EffectEventDispatcher = null) -> String:
	return remove_all_effects(combatant, ActiveEffect.RemovalReason.BATTLE_ENDED, include_persistent, dispatcher)

static func _dispatch(dispatcher: EffectEventDispatcher, event: EffectLifecycleEvent) -> void:
	if dispatcher != null:
		dispatcher.dispatch(event)

static func _add_effect(effect: Effect, source: Combatant, target: Combatant, remaining_turns: int, dispatcher: EffectEventDispatcher = null) -> ApplicationResult:
	assert(find_active_effect(target, effect.effect_id) == null,
		'Effect "%s" is already active on the target.' % effect.effect_id)
	var active_effect := ActiveEffect.new(effect, target, source)
	if remaining_turns > 0:
		active_effect.remaining_turns = remaining_turns
	target.active_effects.append(active_effect)
	var output := "%s applied to %s.\n" % [
		effect._to_string(active_effect.remaining_turns),
		target.get_colored_name()
	]
	output += active_effect.on_apply()
	var result := ApplicationResult.new(ApplicationStatus.ADDED, active_effect, effect.level, 0, output)
	_dispatch(dispatcher, EffectLifecycleEvent.new(EffectLifecycleEvent.EventType.ADDED, active_effect, 0, effect.level))
	return result

static func _remove_effect_instance(active_effect: ActiveEffect, reason: ActiveEffect.RemovalReason, dispatcher: EffectEventDispatcher = null, emit_event: bool = true) -> String:
	if active_effect == null or active_effect.effect == null:
		return ""
	var target := active_effect.target
	var output := active_effect.remove(reason)
	if active_effect in target.active_effects:
		target.active_effects.erase(active_effect)
	output += _get_removal_output(active_effect, reason)
	if emit_event:
		_dispatch(dispatcher, EffectLifecycleEvent.new(EffectLifecycleEvent.EventType.REMOVED, active_effect, active_effect.effect.level, 0, reason))
	return output

static func _get_active_effect_instances(target: Combatant) -> Array[ActiveEffect]:
	if target == null:
		return []
	return target.active_effects.duplicate()

static func _refresh_effect(effect: Effect, source: Combatant, target: Combatant, 
	active_effect: ActiveEffect, remaining_turns: int, dispatcher: EffectEventDispatcher = null) -> ApplicationResult:
	active_effect.refresh_duration(source)
	if remaining_turns > 0:
		active_effect.remaining_turns = remaining_turns
	var output := "%s %d refreshed on %s (%d turns).\n" % [
		effect.effect_name,
		effect.level,
		target.get_colored_name(),
		active_effect.remaining_turns
	]
	var result := ApplicationResult.new(ApplicationStatus.REFRESHED, active_effect, effect.level, active_effect.effect.level, output)
	_dispatch(dispatcher, EffectLifecycleEvent.new(EffectLifecycleEvent.EventType.REFRESHED, active_effect, active_effect.effect.level, effect.level))
	return result

static func _upgrade_effect(effect: Effect, source: Combatant, target: Combatant,
	 active_effect: ActiveEffect, remaining_turns: int, dispatcher: EffectEventDispatcher = null) -> ApplicationResult:
	var previous_level := active_effect.effect.level
	var replacement_source: Combatant = source if source != null else active_effect.source
	var output := _remove_effect_instance(active_effect, ActiveEffect.RemovalReason.REPLACED, dispatcher, false)
	var replacement := ActiveEffect.new(effect, target, replacement_source)
	if remaining_turns > 0:
		replacement.remaining_turns = remaining_turns
	target.active_effects.append(replacement)
	output += replacement.on_apply()
	output += "%s upgraded from level %d to level %d on %s (%d turns).\n" % [
		effect.effect_name,
		previous_level,
		effect.level,
		target.get_colored_name(),
		replacement.remaining_turns,
	]
	var result := ApplicationResult.new(ApplicationStatus.UPGRADED, replacement, effect.level, previous_level, output)
	_dispatch(dispatcher, EffectLifecycleEvent.new(EffectLifecycleEvent.EventType.UPGRADED, replacement, previous_level, effect.level))
	return result

static func _reject_weaker_effect(effect: Effect, target: Combatant, active_effect: ActiveEffect, dispatcher: EffectEventDispatcher = null) -> ApplicationResult:
	var output := "%s level %d had no effect on %s; level %d is already active.\n" % [
		effect.effect_name,
		effect.level,
		target.get_colored_name(),
		active_effect.effect.level
	]
	var result := ApplicationResult.new(ApplicationStatus.REJECTED_WEAKER, active_effect, effect.level, active_effect.effect.level, output)
	_dispatch(dispatcher, EffectLifecycleEvent.new(EffectLifecycleEvent.EventType.REJECTED_WEAKER, active_effect, active_effect.effect.level, effect.level))
	return result

static func _get_removal_output(active_effect: ActiveEffect, reason: ActiveEffect.RemovalReason) -> String:
	var effect_name := active_effect.effect.effect_name
	var target_name := active_effect.target.get_colored_name()
	match reason:
		ActiveEffect.RemovalReason.NATURAL:
			return "%s wore off on %s.\n" % [effect_name, target_name]
		ActiveEffect.RemovalReason.CLEANSED:
			return "%s was cleansed from %s.\n" % [effect_name, target_name]
		ActiveEffect.RemovalReason.RESTED:
			return "%s was removed from %s by resting.\n" % [effect_name, target_name]
		ActiveEffect.RemovalReason.BATTLE_ENDED:
			return "%s ended on %s when the battle ended.\n" % [effect_name, target_name]
		ActiveEffect.RemovalReason.REPLACED:
			return "%s was replaced on %s.\n" % [effect_name, target_name]
	return ""
