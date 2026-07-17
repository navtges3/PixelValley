extends RefCounted
class_name EffectLifecycleEvent

enum EventType {
	ADDED,
	REFRESHED,
	UPGRADED,
	REJECTED_WEAKER,
	TICKED,
	REMOVED,
}

var type: EventType:
	get:
		return _type

var target: Combatant:
	get:
		return _target

var effect_id: StringName:
	get:
		return _effect_id

var level: int:
	get:
		return _level

var previous_level:
	get:
		return _previous_level

var incoming_level:
	get:
		return _incoming_level

var remaining_turns: int:
	get:
		return _remaining_turns

var removal_reason: ActiveEffect.RemovalReason:
	get:
		return _removal_reason

var _type: EventType
var _target: Combatant
var _effect_id: StringName
var _level: int
var _previous_level: int
var _incoming_level: int
var _remaining_turns: int
var _removal_reason: ActiveEffect.RemovalReason

func _init(event_type: EventType, active_effect: ActiveEffect, 
	event_previous_level: int = 0, event_incoming_level: int = 0,
	event_removal_reason: ActiveEffect.RemovalReason = ActiveEffect.RemovalReason.NATURAL) -> void:
		assert(active_effect != null)
		assert(active_effect.effect != null)
		
		_type = event_type
		_target = active_effect.target
		_effect_id = active_effect.effect.effect_id
		_level = active_effect.effect.level
		_previous_level = event_previous_level
		_incoming_level = event_incoming_level
		_remaining_turns = active_effect.remaining_turns
		_removal_reason = event_removal_reason
