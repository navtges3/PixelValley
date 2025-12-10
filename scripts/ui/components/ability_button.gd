extends Button

signal ability_pressed(ability: Ability)

@export var ability: Ability:
	set(value):
		ability = value
		_refresh()

@export var user_energy: int:
	set(value):
		user_energy = value
		_refresh()

func _ready() -> void:
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed():
	emit_signal("ability_pressed", ability)

func _refresh() -> void:
	_update_text()
	_update_tooltip()
	_update_theme()
	_update_disabled()

func _update_text() -> void:
	if ability:
		text = ability.name
		if not ability.is_ready():
			text += " cd:" + str(ability.current_cooldown)
		elif ability.energy_cost > user_energy:
			text += " (No Energy)"
	else:
		text = ""

func _update_tooltip() -> void:
	if ability:
		if ability.is_ready():
			tooltip_text = ability.get_tooltip(GameState.hero.stat_block)
		else:
			tooltip_text = "On cooldown"
	else:
		tooltip_text = ""

func _update_theme() -> void:
	if ability:
		if ability.attack != null:
			theme = preload("res://assets/button_themes/regular/red_button.tres")
		else:
			theme = preload("res://assets/button_themes/regular/green_button.tres")
	else:
		theme = preload("res://assets/button_themes/regular/gray_button.tres")

func _update_disabled() -> void:
	if ability and user_energy:
		disabled = not ability.is_ready() or ability.energy_cost > user_energy
	else:
		disabled = true
