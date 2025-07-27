extends Resource

class_name Village

@export var name: String
@export var max_hp: int
@export var current_hp: int
@export var shop: Shop

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
		"current_hp": current_hp,
		"shop": shop.get_save_data()
	}

static func create_from_data(data: Dictionary) -> Village:
	var village := Village.new()
	village.name = data.get("name", "Lexiton")
	village.max_hp = data.get("max_hp", 100)
	village.current_hp = data.get("current_hp", 100)
	village.shop = Shop.create_from_data(data.get("shop", {}))
	return village
