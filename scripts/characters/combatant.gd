extends Resource
class_name Combatant

const REST_CD := 5

@export var name: String

@export_group("Stats")
@export var max_hp: int = 0
@export var current_hp: int = 0
@export var max_nrg: int = 0
@export var current_nrg: int = 0

@export var attack: int = 0		# modifies physical attacks
@export var magic: int = 0		# modifies magical attacks
@export var defense: int = 0	# modifies physical defense
@export var resist: int = 0		# Modifies magical defense

@export_group("Visuals")
@export var world_visual: SpriteFrames
@export var battle_visual: SpriteFrames
@export var battle_height: int = 64
@export var battle_x_offset: int = 32
@export var hand_positions: Dictionary = {}
@export var hand_rotations: Dictionary = {}

@export_group("Active Effects")
var active_effects: Array[ActiveEffect] = []

var rest_cooldown: int = 0

func get_colored_name() -> String:
	return self.name

func is_alive() -> bool:
	return current_hp > 0

func rest() -> void:
	EffectManager.remove_all_effects(self, ActiveEffect.RemovalReason.RESTED, true)
	current_hp = max_hp
	current_nrg = max_nrg

func meditate() -> void:
	var base_hp := 8
	var base_nrg := 5
	var magic_scale := 1.3
	var defense_scale := 1.5
	var resist_scale := 1.5
	self.rest_cooldown = REST_CD
	self.heal(int(base_hp + (defense * defense_scale) + (resist * resist_scale)))
	self.recover_energy(int(base_nrg + (magic * magic_scale)))

func take_damage(amount: int, type: Attack.AttackType) -> String:
	var damage := _calculate_damage(amount, type)
	current_hp = max(current_hp - damage, 0)
	if damage <= 0:
		return "%s blocked the attack!\n" % self.get_colored_name()
	else:
		return "%s took %d damage.\n" % [self.get_colored_name(), damage]

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)

func use_energy(amount: int) -> bool:
	if current_nrg >= amount:
		current_nrg -= amount
		return true
	else:
		return false

func recover_energy(amount: int) -> void:
	current_nrg = min(current_nrg + amount, max_nrg)

func apply_effect(effect: Effect, source: Combatant = null, remaining_turns: int = 0) -> String:
	var result := EffectManager.apply_effect(effect, source, self, remaining_turns)
	return result.output

func process_active_effects(effects_to_tick: Array[ActiveEffect]) -> String:
	return EffectManager.process_turn_end(self, effects_to_tick)

func remove_effect(effect_id: StringName, reason: ActiveEffect.RemovalReason = ActiveEffect.RemovalReason.CLEANSED) -> String:
	return EffectManager.remove_effect_by_id(self, effect_id, reason)

func clear_active_effects(reason: ActiveEffect.RemovalReason, include_persistent: bool = false) -> void:
	EffectManager.remove_all_effects(self, reason, include_persistent)

func _calculate_damage(amount: int, type: Attack.AttackType) -> int:
	var damage := amount
	match type:
		Attack.AttackType.PHYSICAL:
			damage = max(damage - defense, 0)
		Attack.AttackType.MAGICAL:
			damage = max(damage - resist, 0)
	return damage
