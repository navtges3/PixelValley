extends Node

const SETTINGS_PATH := "user://settings.json"

# ----------------------------
# AUDIO
# ----------------------------
var master_volume := 1.0
var music_volume := 0.8
var sfx_volume := 0.8

# ----------------------------
# VIDEO
# ----------------------------
var fullscreen := false
var maximized := false
var vsync := true

func _ready() -> void:
	load_settings()
	apply_settings()
	get_tree().root.size_changed.connect(_on_window_size_changed)

# ----------------------------
# SAVE / LOAD
# ----------------------------
func save_settings() -> void:
	var data := {
		"audio": {
			"master": master_volume,
			"music": music_volume,
			"sfx": sfx_volume
		},
		"video": {
			"fullscreen": fullscreen,
			"maximized": maximized,
			"vsync": vsync
		}
	}

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings()
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		return

	var audio = data.get("audio", {})
	master_volume = audio.get("master", master_volume)
	music_volume = audio.get("music", music_volume)
	sfx_volume = audio.get("sfx", sfx_volume)

	var video = data.get("video", {})
	fullscreen = video.get("fullscreen", fullscreen)
	maximized = video.get("maximized", maximized)
	vsync = video.get("vsync", vsync)

func apply_settings() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)

	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif maximized:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync
		else DisplayServer.VSYNC_DISABLED
	)

func _set_bus_volume(bus_name: String, volume: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamp(volume, 0.0, 1.0)))

func _on_window_size_changed() -> void:
	var mode := DisplayServer.window_get_mode()
	print("Window mode changed: ", mode)
	if mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
		print("Window is now maximized")
		maximized = true
	elif mode == DisplayServer.WINDOW_MODE_WINDOWED:
		print("Window is now in windowed mode")
		maximized = false
