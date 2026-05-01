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

const MUSIC_PATHS := {
	"background": "res://audio/background_music.mp3",
}

var _music_cache: Dictionary = {}

# ---------------------------------------------------------
# INIT
# ---------------------------------------------------------
func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	_music_player.autoplay = false
	_music_player.volume_db = 0.0
	add_child(_music_player)

	_music_player.finished.connect(_on_music_finished)

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

func play_music_by_id(id: String, fade := true) -> void:
	if not MUSIC_PATHS.has(id):
		push_warning("AudioManager: Unknown music id '%s'" % id)
		return
	if not _music_cache.has(id):
		_music_cache[id] = load(MUSIC_PATHS[id])
	play_music(_music_cache[id], fade)

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

func _on_music_finished() -> void:
	if _current_music != null:
		_music_player.play()

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
	add_child(p)
	p.play()

	p.finished.connect(func(): p.queue_free())

# ---------------------------------------------------------
# DIALOGUE DUCKING
# ---------------------------------------------------------
var _pre_duck_volume_db: float = 0.0

func duck_music(db := -15.0) -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus >= 0:
		_pre_duck_volume_db = AudioServer.get_bus_volume_db(bus)
		AudioServer.set_bus_volume_db(bus, db)

func unduck_music() -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, _pre_duck_volume_db)
