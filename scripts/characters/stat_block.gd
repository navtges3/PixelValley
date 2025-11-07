extends Resource
class_name StatBlock

@export var current_hp := 0
@export var current_nrg := 0
@export var max_hp := 0
@export var max_nrg := 0

@export var attack := 0		# modifies physical attacks
@export var magic := 0		# modifies magical attacks
@export var defense := 0	# modifies physical defense
@export var resistance := 0	# Modifies magical defense

func get_stat(stat: String) -> int:
	match stat:
		"attack":
			return attack
		"magic":
			return magic
		"defense":
			return defense
		"resistance":
			return resistance
	return -1

func set_stat(stat: String, value: int) -> void:
	match stat:
		"attack":
			attack = value
		"magic":
			magic = value
		"defense":
			defense = value
		"resistance":
			resistance = value
