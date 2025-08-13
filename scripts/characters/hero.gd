extends Combatant
class_name Hero

const LEVEL_UP_MULT := 25

@export var hero_class: String
@export var level := 1
@export var experience := 0
@export var inventory: Inventory

func gain_experience(amount: int) -> void:
	experience += amount
	if experience >= level * LEVEL_UP_MULT:
		experience -= level * LEVEL_UP_MULT
		level_up()

func level_up() -> void:
	level += 1
	stat_block.max_hp += 5
	current_hp = stat_block.max_hp
	stat_block.max_nrg += 2
	current_nrg = stat_block.max_nrg
