extends Button

signal item_pressed(item_stack: ItemStack)

@export var item_stack: ItemStack:
	set(value):
		item_stack = value
		_update_text()
		_update_tooltip()
		_update_theme()

func _update_text() -> void:
	if item_stack:
		if item_stack.count > 1:
			text = "%dx %s" % [item_stack.count, item_stack.item.name]
		else:
			text = item_stack.item.name
	else:
		text = ""

func _update_tooltip() -> void:
	if item_stack:
		tooltip_text = item_stack.item._to_string()
	else:
		tooltip_text = ""

func _update_theme() -> void:
	if item_stack:
		theme = item_stack.item.theme
	else:
		theme = preload("res://resources/ui/button_themes/regular/gray_button.tres")


func _on_pressed() -> void:
	item_pressed.emit(item_stack)
