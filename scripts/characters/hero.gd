extends Combatant
class_name Hero

enum HeroClass {
	ASSASSIN,
	KNIGHT,
	PRINCESS
}

const LEVEL_UP_MULT := 25

@export var hero_class: HeroClass
@export var level := 1
@export var experience := 0
@export var skill_points := 0
@export var inventory: Inventory

func get_colored_name() -> String:
	return "[color=green]" + self.name + "[/color]"

func get_class_name() -> String:
	match hero_class:
		HeroClass.ASSASSIN:
			return "Assassin"
		HeroClass.KNIGHT:
			return "Knight"
		HeroClass.PRINCESS:
			return "Princess"
		_:
			return "Unknown"

func gain_experience(amount: int) -> void:
	experience += amount
	if experience >= level * LEVEL_UP_MULT:
		experience -= level * LEVEL_UP_MULT
		level_up()

func level_up() -> void:
	level += 1
	max_hp += 5
	current_hp = max_hp
	max_nrg += 2
	current_nrg = max_nrg
	if level % 5 == 0:
		skill_points += 5
	else:
		skill_points += 2

func use_item(item_id: String) -> String:
	var potion := ItemLoader.get_item(item_id) as Potion
	if potion == null:
		return "%s can't use this item.\n" % get_colored_name()
	var effects := inventory.use_potion(item_id)
	var output := "%s drank %s.\n" % [get_colored_name(), potion.name]
	for effect in effects:
		output += " " + apply_effect(effect.duplicate())
	return output

func update_cooldown() -> void:
	if self.rest_cooldown > 0:
		self.rest_cooldown -= 1
	for ability in inventory.equipped_weapon.abilities:
		if ability.current_cooldown > 0:
			ability.current_cooldown -= 1
