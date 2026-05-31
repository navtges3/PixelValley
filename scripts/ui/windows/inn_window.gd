extends Control
class_name InnWindow

signal closed

@onready var inn_name_label: Label = $PanelContainer/VBoxContainer/InnNameLabel
@onready var rest_feedback_label: Label = $PanelContainer/VBoxContainer/RestFeedbackLabel
@onready var rest_button: Button = $PanelContainer/VBoxContainer/RestButton

func open() -> void:
	inn_name_label.text = GameState.village.inn.name
	rest_feedback_label.visible = false
	rest_button.disabled = false
	show()

func close() -> void:
	hide()
	closed.emit()

func _on_rest_button_pressed() -> void:
	GameState.hero.rest()
	
	for location_id in [ForestLocation.LOCATION_ID, WarCampLocation.LOCATION_ID, CaveLocation.LOCATION_ID]:
		WorldManager.reset_location_spawners(location_id)
	
	SaveManager.save_game()
	rest_button.disabled = true
	rest_feedback_label.visible = true
	rest_feedback_label.text = "You wake up feeling refreshed."

func _on_close_button_pressed() -> void:
	close()
