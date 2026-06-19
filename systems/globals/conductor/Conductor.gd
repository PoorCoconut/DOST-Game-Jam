extends Node

# Variables to define the song
@export var bpm := 128.0
var seconds_per_beat: float

# Tracking the song position
var song_position := 0.0
var song_position_in_beats := 0
var last_reported_beat := 0

# Adjust this if the visuals and audio feel out of sync
var input_delay := 0.0 

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer


# We will use this signal to tell other objects (like the UI) a beat happened
signal beat(position)

func _ready():
	seconds_per_beat = 60.0 / bpm
	play_from_beginning()

func play_from_beginning():
	audio_player.play()

func _process(_delta):
	if audio_player.playing:
		# 1. Get the raw position from the audio player
		song_position = audio_player.get_playback_position()
		
		# 2. Account for the 'jitter' between the audio engine and the game engine
		song_position += AudioServer.get_time_since_last_mix()
		
		# 3. Subtract the output latency (the time it takes for sound to reach your speakers)
		song_position -= AudioServer.get_output_latency()
		
		# 4. Calculate what beat we are on
		song_position_in_beats = int(floor(song_position / seconds_per_beat))
		
		# 5. Report the beat if it's a new one
		_report_beat()

func _report_beat():
	if last_reported_beat < song_position_in_beats:
		last_reported_beat = song_position_in_beats
		emit_signal("beat", last_reported_beat)
		print("Beat: ", last_reported_beat) # Just to see it working in the console
