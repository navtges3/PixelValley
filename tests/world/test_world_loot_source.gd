extends WorldLootSource
class_name TestWorldLootSource

var autosave_count: int = 0

func _autosave_after_claim() -> void:
	autosave_count += 1
