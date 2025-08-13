extends Button

signal ability_pressed(ability: Ability)

@export var ability: Ability

func _ready() -> void:
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed():
	emit_signal("ability_pressed", ability)
