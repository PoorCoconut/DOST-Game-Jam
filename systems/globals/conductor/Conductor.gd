extends Node

@export var active_chart: ChartData
var bpm: float = 120.0
var seconds_per_beat: float = 0.0
var _song_position := 0.0
var _song_position_in_beats := 0.0
var _last_reported_beat := 0

@onready var audio_player: AudioStreamPlayer = $Music
@onready var metronome: AudioStreamPlayer = $Beat

signal beat(position)
signal song_finished


func _ready() -> void:
	Input.set_use_accumulated_input(false)


func load_song(chart: ChartData) -> void:
	active_chart = chart
	bpm = chart.bpm
	seconds_per_beat = 60.0 / bpm
	audio_player.stream = chart.stream
	
	# Reset tracking
	_song_position = 0.0
	_song_position_in_beats = 0.0
	_last_reported_beat = 0
	
	print("[LEVEL] Conductor: Loaded song '", chart.song_name, "'")


func play_song() -> void:
	if audio_player.stream:
		audio_player.play()
	else:
		push_error("[ERROR] Conductor: Tried to play song, but no AudioStream was found in Chart!")


func _process(_delta):
	if audio_player.playing:
		# get the raw position from the audio player
		_song_position = audio_player.get_playback_position()
		
		# account for the 'jitter' between the audio engine and game engine
		_song_position += AudioServer.get_time_since_last_mix()
		
		# subtract the output latency
		_song_position -= AudioServer.get_output_latency()
		
		# calculate what beat we are on
		_song_position_in_beats = _song_position / seconds_per_beat
		
		# report the beat if it's a new one
		_report_beat()


func _report_beat():
	var current_beat_int = int(floor(_song_position_in_beats))
	if _last_reported_beat < current_beat_int:
		_last_reported_beat = current_beat_int
		emit_signal("beat", _last_reported_beat)
		
		# comment these out if necessary
		# metronome.play()
		print("[DEBUG] Beat: ", _last_reported_beat)


func get_beat() -> float:
	return _song_position_in_beats


func get_time() -> float:
	return _song_position
