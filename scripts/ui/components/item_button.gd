extends Button

signal item_pressed(item_stack: ItemStack)

@export var item_stack: ItemStack

func _ready() -> void:
	connect("pressed", Callable(self, "_on_button_pressed"))

func _on_button_pressed() -> void:
	item_pressed.emit(item_stack)