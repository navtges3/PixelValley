extends Node

# ---------------------------------------------------------
# MUSIC
# ---------------------------------------------------------
var _music_player: AudioStreamPlayer
var _music_fade_tween: Tween
var _current_music: AudioStream = null

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const UI_BUS := "UI"

const MUSIC_FADE_TIME := 0.8

# ---------------------------------------------------------
# INIT
# ---------------------------------------------------------
func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	_music_player.autoplay = false
	_music_player.volume_db = 0.0
	add_child(_music_player)

# ---------------------------------------------------------
# MUSIC API
# ---------------------------------------------------------
func play_music(stream: AudioStream, fade := true) -> void:
	if stream == null:
		return
	if _current_music == stream and _music_player.playing:
		return
	_current_music = stream
	if _music_player.playing and fade:
		_fade_out_then_play(stream)
	else:
		_music_player.stream = stream
		_music_player.volume_db = 0.0
		_music_player.play()

func stop_music(fade := true) -> void:
	if not _music_player.playing:
		return
	if fade:
		_fade_out()
	else:
		_music_player.stop()
		_current_music = null

func pause_music() -> void:
	if _music_player.playing:
		_music_player.stream_paused = true

func resume_music() -> void:
	if _music_player.stream_paused:
		_music_player.stream_paused = false

# ---------------------------------------------------------
# FADE HELPERS
# ---------------------------------------------------------
func _fade_out_then_play(stream: AudioStream) -> void:
	_kill_fade()
	_music_fade_tween = create_tween()
	_music_fade_tween.tween_property(_music_player, "volume_db", -80.0, MUSIC_FADE_TIME)
	_music_fade_tween.tween_callback(func():
		_music_player.stop()
		_music_player.stream = stream
		_music_player.volume_db = 0.0
		_music_player.play()
	)

func _fade_out() -> void:
	_kill_fade()
	_music_fade_tween = create_tween()
	_music_fade_tween.tween_property(_music_player, "volume_db", -80.0, MUSIC_FADE_TIME)
	_music_fade_tween.tween_callback(func():
		_music_player.stop()
		_current_music = null
	)

func _kill_fade() -> void:
	if _music_fade_tween and _music_fade_tween.is_running():
		_music_fade_tween.kill()

# ---------------------------------------------------------
# SFX API
# ---------------------------------------------------------
func play_sfx(stream: AudioStream, volume := 1.0) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.bus = SFX_BUS
	p.volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
	p.stream = stream
	add_child(p)
	p.play()
	
	p.finished.connect(func(): p.queue_free())

# ---------------------------------------------------------
# UI SOUND API
# ---------------------------------------------------------
func play_ui(stream: AudioStream, volume := 1.0) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.bus = UI_BUS
	p.volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
	p.stream = stream
	p.play()
	
	p.finished.connect(func(): p.queue_free())

# ---------------------------------------------------------
# DIALOGUE DUCKING
# ---------------------------------------------------------
func duck_music(db := -15.0) -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, db)

func unduck_music() -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus >= 0:
		var vol := SettingsManager.music_volume
		AudioServer.set_bus_volume_db(bus, linear_to_db(vol))
