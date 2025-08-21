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

func use_item(item_stack: ItemStack) -> String:
	if item_stack.item is Potion:
		var potion := item_stack.item as Potion
		var effects := inventory.use_potion(potion)
		for effect in effects:
			self.apply_effect(effect.duplicate())
		return "%s drank %s." % [self.name, potion.name]
	return "%s can't use this item." % self.name

func update_cooldown() -> void:
	if self.rest_cooldown > 0:
		self.rest_cooldown -= 1
	for ability in inventory.weapon.abilities:
		if ability.current_cooldown > 0:
			ability.current_cooldown -= 1
