extends CanvasLayer
class_name WorldHUD

func hide_all() -> void:
	for child in get_children():
		if child is Control:
			child.visible = false

func show_all() -> void:
	for child in get_children():
		if child is Control:
			child.visible = true
