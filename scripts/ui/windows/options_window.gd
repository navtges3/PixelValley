extends GameWindow
class_name OptionsWindow

@onready var master_volume_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MasterVolumeSlider
@onready var music_volume_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/SFXVolumeSlider
@onready var fullscreen_button: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/FullscreenButton
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	super._ready()
	master_volume_slider.value = SettingsManager.master_volume
	music_volume_slider.value = SettingsManager.music_volume
	sfx_volume_slider.value = SettingsManager.sfx_volume
	fullscreen_button.set_pressed_no_signal(SettingsManager.fullscreen)
	_configure_focus_graph()

func _get_default_focus_target() -> Control:
	return master_volume_slider

func _configure_focus_graph() -> void:
	var controls: Array[Control] = [
		master_volume_slider,
		music_volume_slider,
		sfx_volume_slider,
		fullscreen_button,
		close_button,
	]
	for index: int in controls.size():
		var control: Control = controls[index]
		var top_target: Control = controls[maxi(index - 1, 0)]
		var bottom_target: Control = controls[mini(index + 1, controls.size() - 1)]
		control.focus_neighbor_top = control.get_path_to(top_target)
		control.focus_neighbor_bottom = control.get_path_to(bottom_target)

	# These controls do not use horizontal input, so keep it inside the modal.
	fullscreen_button.focus_neighbor_left = fullscreen_button.get_path_to(fullscreen_button)
	fullscreen_button.focus_neighbor_right = fullscreen_button.get_path_to(fullscreen_button)
	close_button.focus_neighbor_left = close_button.get_path_to(close_button)
	close_button.focus_neighbor_right = close_button.get_path_to(close_button)

func _on_fullscreen_button_toggled(toggled: bool) -> void:
	SettingsManager.fullscreen = toggled
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
	fullscreen_button.grab_focus.call_deferred()

func _on_master_volume_slider_value_changed(value: float) -> void:
	SettingsManager.master_volume = value
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_music_volume_slider_value_changed(value: float) -> void:
	SettingsManager.music_volume = value
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_sfx_volume_slider_value_changed(value: float) -> void:
	SettingsManager.sfx_volume = value
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_close_button_pressed() -> void:
	close()
