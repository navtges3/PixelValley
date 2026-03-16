extends Window

@onready var master_volume_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MasterVolumeSlider
@onready var music_volume_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/SFXVolumeSlider

func _ready():
	master_volume_slider.value = SettingsManager.master_volume
	music_volume_slider.value = SettingsManager.music_volume
	sfx_volume_slider.value = SettingsManager.sfx_volume

func _on_master_volume_slider_value_changed(value) -> void:
	SettingsManager.master_volume = value
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_music_volume_slider_value_changed(value) -> void:
	SettingsManager.music_volume = value
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_sfx_volume_slider_value_changed(value) -> void:
	SettingsManager.sfx_volume = value
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_close_button_pressed() -> void:
	self.hide()
