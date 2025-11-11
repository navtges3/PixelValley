extends Button

signal item_pressed(item_stack: ItemStack)

@export var item_stack: ItemStack:
	set(value):
		item_stack = value
		_update_text()
		_update_theme()

func _ready() -> void:
	connect("pressed", Callable(self, "_on_button_pressed"))

func _on_button_pressed() -> void:
	item_pressed.emit(item_stack)

func _update_text() -> void:
	if item_stack:
		if item_stack.count > 1:
			text = "%dx %s" % [item_stack.count, item_stack.item.name]
		else:
			text = item_stack.item.name
	else:
		text = ""

func _update_theme() -> void:
	if item_stack:
		theme = item_stack.item.theme
	else:
		theme = preload("res://assets/button_themes/regular/gray_button.tres")
