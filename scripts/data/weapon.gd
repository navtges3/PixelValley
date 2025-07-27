extends Item

class_name Weapon

@export var rarity: String
@export var abilities: Array[Ability] = []

func update_cooldown() -> void:
	for ability in abilities:
		ability.update_cooldown()

func get_tooltip() -> String:
	var ability_tooltips: String = ""
	for ability in abilities:
		ability_tooltips += "%s\n%s\n" % [ability.name, ability.get_tooltip()]
	return "%s\nRarity: %s\nAbilities:\n%s" % [name, rarity, ability_tooltips.strip_edges()]