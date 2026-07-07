extends Control
class_name GameWindow

signal opened
signal closed

func open() -> void:
	show()
	opened.emit()
	grab_focus()

func close() -> void:
	hide()
	closed.emit()

func is_open() -> bool:
	return is_visible_in_tree()
