extends RefCounted
class_name EffectView

var effect_id: StringName:
	get:
		return _effect_id

var display_name: String:
	get:
		return _display_name

var level: int:
	get:
		return _level

var remaining_turns: int:
	get:
		return _remaining_turns

var persistence: Effect.Persistence:
	get:
		return _persistence

var image: Texture2D:
	get:
		return _image

var tooltip_text: String:
	get:
		return _tooltip_text

var _effect_id: StringName
var _display_name: String
var _level: int
var _remaining_turns: int
var _persistence: Effect.Persistence
var _image: Texture2D
var _tooltip_text: String

func _init(active_effect: ActiveEffect) -> void:
	assert(active_effect != null)
	assert(active_effect.effect != null)
	
	_effect_id = active_effect.effect.effect_id
	_display_name = active_effect.effect.effect_name
	_level = active_effect.effect.level
	_remaining_turns = active_effect.remaining_turns
	_persistence = active_effect.effect.persistence
	_image = active_effect.effect.image
	_tooltip_text = active_effect._to_string()
