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

static func apply_effect(effect: Effect, source: Combatant, target: Combatant, remaining_turns: int = 0) -> ApplicationResult:
	assert(effect != null, "Cannot apply a null Effect.")
	assert(target != null, "Cannot apply an Effect to a null target.")
	assert(effect.effect_id != &"", 'Effect "%s" must have a non-empty effect_id.' % effect.effect_name)
	
	var active_effect := find_active_effect(target, effect.effect_id)
	if active_effect == null:
		return _add_effect(effect, source, target, remaining_turns)
	if effect.level < active_effect.effect.level:
		return _reject_weaker_effect(effect, target, active_effect)
	if effect.level == active_effect.effect.level:
		return _refresh_effect(effect, source, target, active_effect, remaining_turns)
	return _upgrade_effect(effect, source, target, active_effect, remaining_turns)

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

static func get_active_effects(target: Combatant) -> Array[ActiveEffect]:
	if target == null:
		return []
	return target.active_effects.duplicate()

static func validate_unique_effect_ids(effects: Array[Effect]) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary[StringName, Effect] = {}
	for effect: Effect in effects:
		if effect == null:
			continue
		if effect.effect_id == &"":
			errors.append('Effect "%s" has an empty effect_id' % effect.effect_name)
			continue
		if seen_ids.has(effect.effect_id):
			var first_effect: Effect = seen_ids[effect.effect_id]
			errors.append(
				'Duplicate effect_id "%s" used by "%s" and "%s".' % [
					effect.effect_id,
					first_effect.effect_name,
					effect.effect_name,
				]
			)
			continue
		seen_ids[effect.effect_id] = effect
	return errors

# I think I should just use get_active_effects() I will leave this here just in case
static func capture_turn_start(combatant: Combatant) -> Array[ActiveEffect]:
	return get_active_effects(combatant)

static func process_turn_end(combatant: Combatant, effects_at_turn_start: Array[ActiveEffect]) -> String:
	if combatant == null:
		return ""
	var output := ""
	for active_effect: ActiveEffect in effects_at_turn_start:
		if active_effect == null:
			continue
		if active_effect not in combatant.active_effects:
			continue
		if active_effect.target != combatant:
			continue
		output += active_effect.apply_tick()
		active_effect.remaining_turns -= 1
		if active_effect.remaining_turns <= 0:
			output += remove_effect(active_effect, ActiveEffect.RemovalReason.NATURAL)
	return output

static func remove_effect(active_effect: ActiveEffect, reason: ActiveEffect.RemovalReason) -> String:
	if active_effect == null or active_effect.target == null:
		return ""
	var target := active_effect.target
	var output := active_effect.remove(reason)
	if active_effect in target.active_effects:
		target.active_effects.erase(active_effect)
	return output

static func remove_effect_by_id(combatant: Combatant, effect_id: StringName, reason: ActiveEffect.RemovalReason = ActiveEffect.RemovalReason.CLEANSED) -> String:
	var active_effect := find_active_effect(combatant, effect_id)
	if active_effect == null:
		return ""
	return remove_effect(active_effect, reason)

static func remove_all_effects(combatant: Combatant, reason: ActiveEffect.RemovalReason, include_persistent: bool = false) -> String:
	if combatant == null:
		return ""
	var output := ""
	for active_effect: ActiveEffect in get_active_effects(combatant):
		if not include_persistent and active_effect.effect.persistence == Effect.Persistence.PERSISTENT:
			continue
		output += remove_effect(active_effect, reason)
	return output

static func cleanup_after_battle(combatant: Combatant, include_persistent: bool = false) -> String:
	return remove_all_effects(combatant, ActiveEffect.RemovalReason.BATTLE_ENDED, include_persistent)

static func _add_effect(effect: Effect, source: Combatant, target: Combatant, remaining_turns: int) -> ApplicationResult:
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
	return ApplicationResult.new(ApplicationStatus.ADDED, active_effect, effect.level, 0, output)

static func _refresh_effect(effect: Effect, source: Combatant, target: Combatant, active_effect: ActiveEffect, remaining_turns: int) -> ApplicationResult:
	active_effect.refresh_duration(source)
	if remaining_turns > 0:
		active_effect.remaining_turns = remaining_turns
	var output := "%s %d refreshed on %s (%d turns).\n" % [
		effect.effect_name,
		effect.level,
		target.get_colored_name(),
		active_effect.remaining_turns
	]
	return ApplicationResult.new(ApplicationStatus.REFRESHED, active_effect, effect.level, active_effect.effect.level, output)

static func _upgrade_effect(effect: Effect, source: Combatant, target: Combatant, active_effect: ActiveEffect, remaining_turns: int) -> ApplicationResult:
	var previous_level := active_effect.effect.level
	var output := active_effect.upgrade_to(effect, source)
	if remaining_turns > 0:
		active_effect.remaining_turns = remaining_turns
	output += "%s upgraded from level %d to level %d on %s (%d turns).\n" % [
		effect.effect_name,
		previous_level,
		effect.level,
		target.get_colored_name(),
		active_effect.remaining_turns
	]
	return ApplicationResult.new(ApplicationStatus.UPGRADED, active_effect, effect.level, previous_level, output)

static func _reject_weaker_effect(effect: Effect, target: Combatant, active_effect: ActiveEffect) -> ApplicationResult:
	var output := "%s level %d had no effect on %s; level %d is already active.\n" % [
		effect.effect_name,
		effect.level,
		target.get_colored_name(),
		active_effect.effect.level
	]
	return ApplicationResult.new(ApplicationStatus.REJECTED_WEAKER, active_effect, effect.level, active_effect.effect.level, output)
