extends Node
class_name EffectManager

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
