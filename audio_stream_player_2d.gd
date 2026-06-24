extends Node2D

@export var chart_resource: ChartData
@export var snap_divisor: int = 4 # 4 = 1/4 notes, 8 = 1/8 notes

var is_recording: bool = false

# Lanes configuration matching your game setup
const RECORDER_LANES = ["lane1", "lane2", "lane3", "lane4"]
var current_mode: String = "low (+)"

# Spectrum Analyzer for Auto-Mapping Peaks (Strategy 2)
var analyzer: AudioEffectSpectrumAnalyzerInstance
@export var auto_threshold: float = -20.0 # dB threshold for spawning notes
@export var peak_cooldown_beats: float = 0.5 # Min distance between auto-notes
var last_spawned_beat: float = -999.0

func _ready() -> void:
	if chart_resource:
		Conductor.load_song(chart_resource)
		# Initialize your audio bus effect if doing auto-analysis
		var bus_idx = AudioServer.get_bus_index("Master")
		# Make sure you have a SpectrumAnalyzer effect on your Master or a dedicated Bus!
		for i in AudioServer.get_bus_effect_count(bus_idx):
			if AudioServer.get_bus_effect(bus_idx, i) is AudioEffectSpectrumAnalyzer:
				analyzer = AudioServer.get_bus_effect_instance(bus_idx, i)

func _process(_delta: float) -> void:
	if not is_recording: return
	
	var current_beat = Conductor.get_beat()
	
	# --- STRATEGY 1: LIVE KEYBOARD TAP RECORDING ---
	if Input.is_action_just_pressed("transform"):
		current_mode = "high (x)" if current_mode == "low (+)" else "low (+)"
		print("Recording Mode Switched to: ", current_mode)

	for lane_idx in range(RECORDER_LANES.size()):
		if Input.is_action_just_pressed(RECORDER_LANES[lane_idx]):
			var snapped_beat = snapped(current_beat, 1.0 / snap_divisor)
			add_note_to_chart(snapped_beat, lane_idx, current_mode)
			
	# --- STRATEGY 2: FULLY AUTO BASS/PEAK DETECTION ---
	if analyzer and Input.is_key_pressed(KEY_P): # Hold P to auto-generate from music volume spikes
		var magnitude = analyzer.get_magnitude_for_frequency_range(20, 150).length() # Bass frequencies
		var db = linear_to_db(magnitude)
		
		if db > auto_threshold and (current_beat - last_spawned_beat) >= peak_cooldown_beats:
			var snapped_beat = snapped(current_beat, 1.0 / snap_divisor)
			var random_lane = randi() % 4
			add_note_to_chart(snapped_beat, random_lane, current_mode)
			last_spawned_beat = snapped_beat

func toggle_recording() -> void:
	is_recording = !is_recording
	if is_recording:
		Conductor.play_song()
		print("--- RECORDING STARTED ---")
	else:
		Conductor.stop_song() # Or audio_player.stop() depending on Conductor setup
		save_chart()

func add_note_to_chart(beat: float, lane: int, mode_str: String) -> void:
	# Check if note already exists to prevent duplicates
	for note in chart_resource.notes:
		if abs(note.beat_start - beat) < 0.01 and note.lane == lane and note.mode == mode_str:
			return # Duplicate found, skip
			
	var new_note = NoteData.new()
	new_note.beat_start = beat
	new_note.beat_end = 0.0 # Tap note default
	new_note.lane = lane
	new_note.mode = mode_str
	
	chart_resource.notes.append(new_note)
	print("Recorded: Beat ", beat, " | Lane ", lane, " | Mode ", mode_str)

func save_chart() -> void:
	# Keep notes sorted chronologically so your Spawner script can read them properly
	chart_resource.notes.sort_custom(func(a, b): return a.beat_start < b.beat_start)
	ResourceSaver.save(chart_resource, chart_resource.resource_path)
	print("--- CHART SORTED & HARD SAVED ---")

func _on_button_pressed() -> void:
	toggle_recording()
