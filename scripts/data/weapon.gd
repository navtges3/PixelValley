extends Item

class_name Weapon

@export var rarity: Rarity = Rarity.COMMON
@export var abilities: Array[Ability] = []

func update_cooldown() -> void:
	for ability in abilities:
		ability.update_cooldown()

func _to_string() -> String:
	var ability_tooltips: String = ""
	for ability in abilities:
		ability_tooltips += "%s\n%s\n" % [ability.name, ability._to_string()]
	return "%s\nRarity: %s\nAbilities:\n%s" % [name, rarity_to_string(rarity), ability_tooltips.strip_edges()]