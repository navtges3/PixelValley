extends PopupPanel

@onready var master_volume_slider: HSlider = $VBoxContainer/MasterVolumeSlider
@onready var music_volume_slider: HSlider = $VBoxContainer/MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = $VBoxContainer/SFXVolumeSlider
@onready var close_button = $VBoxContainer/CloseButton

func _ready():
	master_volume_slider.value = SettingsManager.master_volume
	music_volume_slider.value = SettingsManager.music_volume
	sfx_volume_slider.value = SettingsManager.sfx_volume
	
	master_volume_slider.value_changed.connect(_on_master_volume_slider_value_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_slider_value_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_slider_value_changed)

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

func _on_CloseButton_pressed():
	hide()
