extends Combatant
class_name Monster

const HEALTH_WEIGHT := 0.5

@export var monster_id: MonsterLoader.MonsterID
@export var basic_attack: Ability
@export var conditional_abilities: Array[Ability]
@export var gold: int
@export var gold_variance: float = 0.2
@export var loot: DropTable = null

func get_colored_name() -> String:
	return "[color=red]" + self.name + "[/color]"

func choose_ability(target: Combatant) -> Ability:
	for ability in conditional_abilities:
		if ability.is_ready(self, target) and current_nrg >= ability.energy_cost:
			return ability
	return basic_attack

func update_cooldown() -> void:
	if self.basic_attack.current_cooldown > 0:
		self.basic_attack.current_cooldown -= 1
	for ability in conditional_abilities:
		if ability.current_cooldown > 0:
			ability.current_cooldown -= 1

func calculate_experience() -> int:
	var health_exp := int(max_hp * HEALTH_WEIGHT)
	return health_exp

func calculate_gold() -> int:
	var variance := gold * gold_variance
	return int(gold + randf_range(-variance, variance))

func roll_loot(hero_class: Hero.HeroClass) -> Dictionary:
	if loot == null:
		return {}
	return loot.roll(hero_class)
