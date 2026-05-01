extends Button

signal item_pressed(item_id: String)

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
		tooltip_text = item.to_string() if item.has_method("to_string") else ""
		theme = item.theme
	else:
		text = ""
		tooltip_text = ""
		theme = preload("res://resources/ui/button_themes/regular/gray_button.tres")

func _on_pressed() -> void:
	item_pressed.emit(item_id)
