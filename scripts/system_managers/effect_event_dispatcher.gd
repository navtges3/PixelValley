extends RefCounted
class_name EffectEventDispatcher

signal lifecycle_event(event: EffectLifecycleEvent)

func dispatch(event: EffectLifecycleEvent) -> void:
	if event == null:
		return
	lifecycle_event.emit(event)
