extends Resource
class_name MonsterRequirement

@export var monster: Monster
@export var target_amount: int = 1
@export var current_amount: int = 0

func get_save_data() -> Dictionary:
	return {
		"monster_path": monster.resource_path,
		"target_amount": target_amount,
		"current_amount": current_amount
	}

static func load_from_data(data: Dictionary) -> MonsterRequirement:
	var requirement := MonsterRequirement.new()
	requirement.monster = load(data.get("monster_path", ""))
	requirement.target_amount = data.get("target_amount", 1)
	requirement.current_amount = data.get("current_amount", 0)
	return requirement
