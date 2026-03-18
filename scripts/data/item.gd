extends Resource
class_name Item

enum Rarity {
	COMMON,
	RARE,
	LEGENDARY
}

@export var name: String
@export var description: String
@export var theme: Theme = preload("res://resources/ui/button_themes/regular/gray_button.tres")
@export var value: int

static func rarity_to_string(rarity: Rarity) -> String:
	match rarity:
		Rarity.COMMON:
			return "Common"
		Rarity.RARE:
			return "Rare"
		Rarity.LEGENDARY:
			return "Legendary"
	return "Unknown"
