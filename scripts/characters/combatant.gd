extends Resource
class_name Combatant

const REST_CD := 5

@export var name: String
@export var portrait: Texture2D
@export var battle_visual: BattleVisualData
@export var active_effects: Array[ActiveEffect] = []
@export var stat_block: StatBlock
var rest_cooldown = 0

func get_colored_name() -> String:
	return self.name

func is_alive() -> bool:
	return stat_block.current_hp > 0

func rest() -> void:
	self.stat_block.current_hp = self.stat_block.max_hp
	self.stat_block.current_nrg = self.stat_block.max_nrg
	active_effects.clear()

func meditate() -> void:
	var base_hp = 8
	var base_nrg = 5
	var magic_scale = 1.3
	var defense_scale = 1.5
	var resistance_scale = 1.5
	self.rest_cooldown = REST_CD
	self.heal(base_hp + (stat_block.defense * defense_scale) + (stat_block.resistance * resistance_scale))
	self.recover_energy(base_nrg + (stat_block.magic * magic_scale))

func take_damage(amount: int, type: Attack.AttackType) -> String:
	var damage = _calculate_damage(amount, type)
	self.stat_block.current_hp = max(self.stat_block.current_hp - damage, 0)
	if damage <= 0:
		return "%s blocked the attack!\n" % self.get_colored_name()
	else:
		return "%s took %d damage.\n" % [self.get_colored_name(), damage]

func heal(amount: int) -> void:
	self.stat_block.current_hp = min(self.stat_block.current_hp + amount, self.stat_block.max_hp)

func use_energy(amount: int) -> bool:
	if self.stat_block.current_nrg >= amount:
		self.stat_block.current_nrg -= amount
		return true
	else:
		return false

func recover_energy(amount: int) -> void:
	self.stat_block.current_nrg = min(self.stat_block.current_nrg + amount, self.stat_block.max_nrg)

func apply_effect(effect: Effect, source = null, remaining_turns := 0) -> String:
	var ae = ActiveEffect.new(effect, self, source)
	if remaining_turns > 0:
		ae.remaining_turns = remaining_turns
	active_effects.append(ae)
	ae.on_apply()
	return "%s applied.\n" % effect._to_string()

func process_active_effects() -> String:
	var output := ""
	for ae in active_effects:
		output += ae.on_tick()
	for ae in active_effects.duplicate():
		if ae.remaining_turns <= 0:
			active_effects.erase(ae)
	return output

func _calculate_damage(amount: int, type: Attack.AttackType) -> int:
	var damage = amount
	match type:
		Attack.AttackType.PHYSICAL:
			damage = max(damage - self.stat_block.defense, 0)
		Attack.AttackType.MAGICAL:
			damage = max(damage - self.stat_block.resistance, 0)
	return damage
