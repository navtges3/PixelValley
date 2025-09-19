extends Resource
class_name Combatant

const REST_CD := 5

@export var name: String
@export var portrait: Texture2D
@export var active_effects: Array[Effect] = []
@export var stat_block: StatBlock
@export var attack_modifier: int = 0
@export var magic_modifier: int = 0
@export var defense_modifier: int = 0
@export var resistance_modifier: int = 0
@export var rest_cooldown: int = 0

func is_alive() -> bool:
	return stat_block.current_hp > 0

func rest() -> void:
	if rest_cooldown <= 0:
		self.heal(int(self.stat_block.max_hp * 0.5))
		self.recover_energy(self.stat_block.max_nrg)
		rest_cooldown = REST_CD

func take_damage(amount: int, type: AttackAbility.AttackType) -> String:
	var damage = amount
	match type:
		AttackAbility.AttackType.PHYSICAL:
			var modifier = self.stat_block.defense + self.defense_modifier
			damage = max(damage - modifier, 0)
		AttackAbility.AttackType.MAGICAL:
			var modifier = self.stat_block.resistance + self.resistance_modifier
			damage = max(damage - modifier, 0)
	self.stat_block.current_hp = max(self.stat_block.current_hp - damage, 0)
	if damage <= 0:
		return "%s blocked the attack!" % self.name
	else:
		return "%s took %d damage." % [self.name, damage]

func heal(amount: int) -> void:
	self.stat_block.current_hp = min(self.stat_block.stat_block.current_hp + amount, self.stat_block.max_hp)

func use_energy(amount: int) -> bool:
	if self.stat_block.current_nrg >= amount:
		self.stat_block.current_nrg -= amount
		return true
	else:
		return false

func recover_energy(amount: int) -> void:
	self.stat_block.current_nrg = min(self.stat_block.current_nrg + amount, self.stat_block.max_nrg)

func apply_effect(effect: Effect) -> String:
	if effect.duration <= 0:
		return "Effect has expired."
	active_effects.append(effect)
	return "%s applied." % effect.get_tooltip()

func process_active_effects() -> void:
	self.attack_modifier = 0
	self.magic_modifier = 0
	self.defense_modifier = 0
	self.resistance_modifier = 0
	for i in range(active_effects.size() -1, -1, -1):
		var effect = active_effects[i]
		match effect.type:
			Effect.EffectType.HEAL:
				print("Healing effect applied.")
				self.stat_block.current_hp = min(self.stat_block.current_hp + effect.strength, self.stat_block.max_hp)
			Effect.EffectType.ENERGY:
				print("Energy effect applied.")
				self.stat_block.current_nrg = min(self.stat_block.current_nrg + effect.strength, self.stat_block.max_nrg)
			Effect.EffectType.BUFF_ATTACK:
				print("Attack buff applied.")
				self.attack_modifier += effect.strength
			Effect.EffectType.BUFF_MAGIC:
				print("Magic buff applied.")
				self.magic_modifier += effect.strength
			Effect.EffectType.BUFF_DEFENSE:
				print("Defense buff applied.")
				self.defense_modifier += effect.strength
			Effect.EffectType.BUFF_RESISTANCE:
				print("Resistance buff applied.")
				self.resistance_modifier += effect.strength
		effect.duration -= 1
		if effect.duration <= 0:
			active_effects.remove_at(i)
			print("Effect '%s' has expired." % effect.type_to_string())
