extends Node

# SONG INFORMATION
var active_chart: ChartData
var bpm: float = 120.0
var seconds_per_beat: float = 0.0

# SONG TIMING
var _song_position := 0.0
var _song_position_in_beats := 0.0
var _last_reported_beat := 0

# GAMEPLAY TIMING
const HIT_RADIUS: float  = 67.0
const BASE_SCROLL_SPEED: float = 500.0   # 1x baseline — do NOT use directly; use Settings.current_scroll_speed
const MISS_WINDOW: float = 0.10

@onready var audio_player: AudioStreamPlayer = $Music
@onready var metronome: AudioStreamPlayer    = $Beat

signal beat(position)
signal song_finished


func _ready() -> void:
	Input.set_use_accumulated_input(false)
	audio_player.finished.connect(_on_song_finished)
	print("[CONDUCTOR] finished signal connected: ", audio_player.finished.is_connected(_on_song_finished))


func load_song(chart: ChartData) -> void:
	active_chart = chart
	bpm = chart.bpm
	seconds_per_beat = 60.0 / bpm
	audio_player.stream = chart.stream

	_song_position = 0.0
	_song_position_in_beats = 0.0
	_last_reported_beat = 0

	print("[AUDIO] Loaded song '", chart.song_name, "' by ", chart.artist)


func play_song() -> void:
	if audio_player.stream:
		audio_player.play()
	else:
		push_error("[ERROR] Tried to play song, but no AudioStream was found in Chart!")


func _process(_delta):
	if audio_player.playing:
		# raw playback position
		_song_position = audio_player.get_playback_position()

		# account for jitter between audio and game engine
		_song_position += AudioServer.get_time_since_last_mix()

		# subtract output latency
		_song_position -= AudioServer.get_output_latency()

		# apply user audio offset (in seconds; positive = notes come later, negative = earlier)
		_song_position += Settings.audio_offset

		# calculate beat
		_song_position_in_beats = _song_position / seconds_per_beat

		_report_beat()


func _report_beat():
	var current_beat_int = int(floor(_song_position_in_beats))
	if _last_reported_beat < current_beat_int:
		_last_reported_beat = current_beat_int
		emit_signal("beat", _last_reported_beat)
		# metronome.play()


func _on_song_finished() -> void:
	print("[CONDUCTOR] song_finished emitted")
	emit_signal("song_finished")


func get_beat() -> float:
	return _song_position_in_beats


func get_time() -> float:
	return _song_position

func is_playing() -> bool:
	return audio_player.playing
