extends Button
class_name ItemButton

signal item_pressed(item_id: String)

var item_tooltip_text: String = ""

@export var item_id: String = "":
	set(value):
		item_id = value
		_refresh()

@export var count: int = 1:
	set(value):
		count = value
		_refresh()

func _refresh() -> void:
	var item := ItemLoader.get_item(item_id)
	if item:
		text = "%dx %s" % [count, item.name] if count > 1 else item.name
		item_tooltip_text = item.to_string() if item.has_method("to_string") else ""
		theme = item.theme
	else:
		text = ""
		item_tooltip_text = ""
		theme = ThemeManager.GRAY_BUTTON
	tooltip_text = ""

func _on_pressed() -> void:
	item_pressed.emit(item_id)
