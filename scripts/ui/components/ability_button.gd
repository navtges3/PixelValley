extends Button

signal ability_pressed(ability: Ability)

@export var ability: Ability:
	set(value):
		ability = value
		_update_text()
		_update_tooltip()
		_update_theme()
		disabled = !ability.is_ready()

func _ready() -> void:
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed():
	emit_signal("ability_pressed", ability)

func _update_text() -> void:
	if ability:
		text = ability.name
		if !ability.is_ready():
			text += " cd:" + str(ability.current_cooldown)
	else:
		text = ""
		
func _update_tooltip() -> void:
	if ability:
		if ability.is_ready():
			tooltip_text = ability.get_tooltip()
		else:
			tooltip_text = ""
	else:
		tooltip_text = ""

func _update_theme() -> void:
	if ability:
		if ability is AttackAbility:
			theme = preload("res://assets/button_themes/regular/red_button.tres")
		elif ability is UtilityAbility:
			theme = preload("res://assets/button_themes/regular/green_button.tres")
		else:
			theme = preload("res://assets/button_themes/regular/gray_button.tres")
	else:
		theme = preload("res://assets/button_themes/regular/gray_button.tres")
