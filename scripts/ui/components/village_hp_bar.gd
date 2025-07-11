extends HBoxContainer

var current_hp: int
var max_hp: int

func _ready() -> void:
	var village: Village = GameState.village
	max_hp = village.max_hp
	current_hp = village.current_hp
	$VillageLabel.text = village.name
	update_bar()

func set_hp(value: int) -> void:
	current_hp = clamp(value, 0, max_hp)
	update_bar()

func update_bar():
	$ProgressBar.value = current_hp
