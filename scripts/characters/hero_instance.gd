extends RefCounted

class_name HeroInstance

var hero_name: String = "Princess Lex"
var hero_class: HeroClass = null
var max_hp: int = 25
var current_hp: int = 0
var max_nrg: int = 10
var current_nrg: int = 0
var level: int = 1
var experience: int = 0
var weapon: Weapon = null
var potion_belt: Array[PotionStack] = []
var active_effects: Array[Effect] = []
var attack_modifier: int = 0

static func create_new(hero_name_in: String, hero_class_in: HeroClass) -> HeroInstance:
	print("Creating new HeroInstance with name: %s and class: %s" % [hero_name_in, hero_class_in.hero_class_name])
	var hero_instance = HeroInstance.new()
	hero_instance.hero_name = hero_name_in
	hero_instance.hero_class = hero_class_in
	hero_instance.max_hp = hero_class_in.base_max_hp
	hero_instance.current_hp = hero_instance.max_hp
	hero_instance.max_nrg = hero_class_in.base_max_nrg
	hero_instance.current_nrg = hero_instance.max_nrg
	hero_instance.weapon = hero_class_in.base_weapon
	for potion in hero_class_in.base_potion_belt:
		hero_instance.add_potion(potion)
	return hero_instance

static func create_from_data(data: Dictionary) -> HeroInstance:
	print("Creating HeroInstance from data: %s" % data)
	var hero_instance = HeroInstance.new()
	hero_instance.hero_name = data.get("hero_name", "Princess Lex")
	var hero_class_path = data.get("hero_class_path", "")
	if hero_class_path:
		hero_instance.hero_class = load(hero_class_path) as HeroClass
		if not hero_instance.hero_class:
			push_error("Hero class path is invalid or missing.")
			return null
	else:
		push_error("Hero class path is missing.")
		return null
	hero_instance.max_hp = data.get("max_hp", 25)
	hero_instance.current_hp = data.get("current_hp", hero_instance.max_hp)
	hero_instance.max_nrg = data.get("max_nrg", 10)
	hero_instance.current_nrg = data.get("current_nrg", hero_instance.max_nrg)
	hero_instance.level = data.get("level", 1)
	hero_instance.experience = data.get("experience", 0)
	var weapon_path = data.get("weapon", "")
	if weapon_path:
		hero_instance.weapon = load(weapon_path) as Weapon
		if not hero_instance.weapon:
			push_error("Weapon path is invalid or missing.")
			return null
	else:
		hero_instance.weapon = null
	return hero_instance

func get_save_data() -> Dictionary:
	return {
		"hero_name": self.hero_name,
		"hero_class_path": self.hero_class.resource_path if hero_class else "",
		"max_hp": self.max_hp,
		"current_hp": self.current_hp,
		"max_nrg": self.max_nrg,
		"current_nrg": self.current_nrg,
		"level": self.level,
		"experience": self.experience,
		"weapon": self.weapon.resource_path if self.weapon else "",
	}

func update_cooldown() -> void:
	process_active_effects()
	if self.weapon:
		self.weapon.update_cooldown()

func use_ability(ability_name: String, target: Monster) -> Dictionary:
	for ability in self.weapon.abilities:
		if ability.name == ability_name:
			if not ability.is_ready():
				return {
					"success": false,
					"message": "Ability '%s' is on cooldown." % ability.name
				}
			if ability.energy_cost > self.current_nrg:
				return {
					"success": false,
					"message": "Not enough energy to use '%s'." % ability.name
				}
			# Ability is ready to use
			if ability is AttackAbility:
				var damage_dealt = ability.apply_attack(target, self.attack_modifier)
				self.use_energy(ability.energy_cost)
				return {
					"success": true,
					"message": "Used %s on %s, dealing %d damage." % [ability.name, target.name, damage_dealt]
				}
			elif ability is UtilityAbility:
				if ability.apply_utility(self):
					self.use_energy(ability.energy_cost)
					return {
						"success": true,
						"message": "Used %s on self, applying %s effect for %d turns." % [ability.name, ability.effect.type_to_string(), ability.effect.duration]
					}
				else:
					return {
						"success": false,
						"message": "Utility ability failed to apply."
					}
			else:
				return {
					"success": false,
					"message": "Unknown ability type."
				}
	return {
		"success": false,
		"message": "Ability '%s' not found." % ability_name
	}

func get_ability_by_name(ability_name: String) -> Ability:
	for ability in self.weapon.abilities:
		if ability.name == ability_name:
			return ability
	push_error("Ability '%s' not found in weapon abilities." % ability_name)
	return null

func can_use_ability(ability_name: String) -> bool:
	for ability in self.weapon.abilities:
		if ability.name == ability_name:
			return self.current_nrg >= ability.energy_cost
	return false

func can_use_abilities() -> bool:
	for ability in self.weapon.abilities:
		if self.can_use_ability(ability.name):
			return true
	return false

func add_potion(potion: Potion) -> void:
	for stack in potion_belt:
		if stack.potion == potion:
			stack.count += 1
			return
	potion_belt.append(PotionStack.new(potion))

func use_potion(potion_name: String) -> Dictionary:
	for stack in potion_belt:
		if stack.potion.name == potion_name and stack.count > 0:
			apply_effect(stack.potion.effect)
			stack.count -= 1
			return {
				"success": true,
				"message": "%s drank a %s" % [self.hero_name, potion_name]
			}
	return {
		"success": false,
		"message": "%s does not have a %s" % [self.hero_name, potion_name]
	}

func apply_effect(effect: Effect) -> void:
	if effect.duration <= 0:
		return

	active_effects.append(effect)

	print("Applied effect '%s' with strength %d for %d turns." % [effect.type_to_string(), effect.strength, effect.duration])

func process_active_effects() -> void:
	self.attack_modifier = 0  # Reset attack modifier each turn
	for i in active_effects.size():
		var effect = active_effects[i]
		print("Processing effect '%s' with strength %d, duration %d" % [effect.type_to_string(), effect.strength, effect.duration])
		match effect.type:
			Effect.EffectType.HEAL:
				print("Healing effect applied.")
				self.heal(effect.strength)
			Effect.EffectType.BUFF_ATTACK:
				print("Attack buff applied.")
				self.attack_modifier += effect.strength
		effect.duration -= 1
		if effect.duration <= 0:
			active_effects.remove_at(i)
			print("Effect '%s' has expired." % effect.type_to_string())

func rest() -> void:
	self.heal(int(self.max_hp * 0.5))
	self.recover_energy(self.max_nrg)

func take_damage(amount: int) -> void:
	self.current_hp = max(self.current_hp - amount, 0)

func heal(amount: int) -> void:
	self.current_hp = min(self.current_hp + amount, self.max_hp)

func is_alive() -> bool:
	return self.current_hp > 0

func use_energy(amount: int) -> bool:
	if self.current_nrg >= amount:
		self.current_nrg -= amount
		return true
	else:
		return false

func recover_energy(amount: int) -> void:
	self.current_nrg = min(self.current_nrg + amount, self.max_nrg)

func get_energy_percentage() -> float:
	if self.max_nrg == 0:
		return 0.0
	return float(self.current_nrg) / float(self.max_nrg)

func gain_experience(amount: int) -> void:
	self.experience += amount
	if self.experience >= self.level * 100:
		self.experience -= self.level * 100
		level_up()

func level_up() -> void:
	self.level += 1
	self.max_hp += 5
	self.max_nrg += 2
