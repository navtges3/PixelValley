extends Resource

class_name Village

@export var name := "Lexiton"
@export var max_hp := 100
@export var current_hp := 100

func take_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)

func is_destroyed() -> bool:
	return current_hp <= 0

func get_save_data() -> Dictionary:
	return {
		"name": name,
		"max_hp": max_hp,
		"current_hp": current_hp
	}

func load_from_data(data: Dictionary) -> void:
	self.name = data.get("name", "Lexiton")
	self.max_hp = data.get("max_hp", 100)
	self.current_hp = data.get("current_hp", 100)