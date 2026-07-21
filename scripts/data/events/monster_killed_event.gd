extends GameplayEvent
class_name MonsterKilledEvent

var monster_id: MonsterLoader.MonsterID
var location_id: String

func _init(_monster_id: MonsterLoader.MonsterID, _location_id: String = "") -> void:
	monster_id = _monster_id
	location_id = _location_id
