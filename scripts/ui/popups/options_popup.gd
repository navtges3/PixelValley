extends PopupPanel

# Get node references
@onready var volume_slider = $VBoxContainer/HBoxContainer/VolumeSlider
@onready var close_button = $VBoxContainer/CloseButton
@onready var music_player = $"/root/MusicController"

func _ready():
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	load_volume_settings()
	volume_slider.value = db_to_linear(music_player.volume_db) * 100

func _on_volume_slider_value_changed(value):
	var db_value = linear_to_db(value / 100)
	music_player.volume_db = db_value

func save_volume_settings(volume_value):
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", volume_value)
	config.save("res://settings.cfg")
	print("Saving new volume")

func load_volume_settings():
	var config = ConfigFile.new()
	var err = config.load("res://settings.cfg")

	if err == OK:
		var saved_volume = config.get_value("audio", "music_volume", 50)
		music_player.volume_db = linear_to_db(saved_volume / 100)

func _on_CloseButton_pressed():
	save_volume_settings(volume_slider.value)
	hide()