extends Node2D

@export_group("Note Scenes")
@export var note_scene: PackedScene
@onready var replay_recorder: Node = %ReplayRecorder
@export var hold_note_scene: PackedScene

# --- FOR PREVIEW ---
@export var is_preview: bool = false

var chart_resource: Resource

# (+): N, E, S, W | (x): NE, SE, SW, NW
var plus_angles: Array = [-90.0, 0.0, 90.0, 180.0]
var x_angles: Array   = [-45.0, 45.0, 135.0, 225.0]

var active_notes: Dictionary = {
	"+": [[], [], [], []],
	"x": [[], [], [], []],
}

var active_hold_notes: Dictionary = {
	"+": [[], [], [], []],
	"x": [[], [], [], []],
}

var note_index: int = 0


func _ready():
	if SceneManager.selected_chart:
		chart_resource = SceneManager.selected_chart
	else:
		chart_resource = load("res://scenes/charts/mus_breakbeat.tres")

	chart_resource.sort_notes()
	ScoreSystem.load_chart(chart_resource)
	replay_recorder.start_recording(chart_resource)
	Conductor.load_song(chart_resource)

	if not is_preview:
		Conductor.play_song()


func _get_spawn_ahead_beats() -> float:
	# Golden Rule: faster scroll speed = notes must spawn sooner.
	# We calculate how many beats ahead a note needs to spawn so it
	# travels from spawn point to HIT_RADIUS exactly on time.
	
	# travel_distance = 400px (screen edge) - HIT_RADIUS (67px) = 333px
	# actual speed     = BASE_SCROLL_SPEED * current_scroll_speed
	# seconds_to_reach = travel_distance / actual_speed
	# beats_to_reach   = seconds_to_reach / seconds_per_beat

	var actual_speed: float = Conductor.BASE_SCROLL_SPEED * Settings.current_scroll_speed
	var travel_distance: float = 400.0 - Conductor.HIT_RADIUS
	var seconds_to_reach: float = travel_distance / actual_speed
	var beats_to_reach: float = seconds_to_reach / Conductor.seconds_per_beat

	# Safety floor: at very high scroll speeds, beats_to_reach can shrink to a
	# fraction smaller than a single frame's worth of beat-progress. When that
	# happens the spawn check in _process() can skip right past the spawn
	# window between two frames, so the note spawns late and visually "pops"
	# or overshoots past the hit ring instead of traveling to it smoothly.
	# We guarantee at least ~3 frames of travel time so spawning never gets
	# skipped, regardless of scroll speed.
	var min_seconds_buffer: float = (1.0 / 60.0) * 3.0
	var min_beats_buffer: float = min_seconds_buffer / Conductor.seconds_per_beat
	beats_to_reach = max(beats_to_reach, min_beats_buffer)

	return beats_to_reach


func _process(_delta: float) -> void:
	if chart_resource == null:
		return

	var current_beat: float = Conductor.get_beat()
	var spawn_beats: float  = _get_spawn_ahead_beats()
	var beat_groups := {}

	while note_index < chart_resource.notes.size():
		var data: NoteData = chart_resource.notes[note_index]

		if current_beat >= data.beat_start - spawn_beats:
			var note = spawn_note(data)
			var b_key = data.beat_start

			if not beat_groups.has(b_key):
				beat_groups[b_key] = []
			beat_groups[b_key].append(note)

			var mode = "+" if data.mode.contains("+") else "x"
			VisualEffects.setup_note_visuals(note, mode)

			note_index += 1
		else:
			break

	# SYNC LOGIC — highlight notes that share the same beat
	for b in beat_groups:
		var group = beat_groups[b]
		if group.size() > 1:
			VisualEffects.apply_sync_visuals(group)


func spawn_note(data: NoteData) -> Node2D:
	var lane_idx = data.lane
	var is_hold  = data.is_hold_note()

	var mode   = data.mode_type()
	var angles = plus_angles if mode == "+" else x_angles
	var angle_rad = deg_to_rad(angles[lane_idx])
	var direction = Vector2(cos(angle_rad), sin(angle_rad))

	var note_node
	if is_hold:
		note_node = hold_note_scene.instantiate()
		active_hold_notes[mode][lane_idx].append(note_node)
	else:
		note_node = note_scene.instantiate()
		active_notes[mode][lane_idx].append(note_node)
	
	# instantiate
	get_parent().add_child(note_node)

	var target_time = data.beat_start * Conductor.seconds_per_beat
	if is_hold:
		var end_time = data.beat_end * Conductor.seconds_per_beat
		var duration = data.beat_end - data.beat_start
		note_node.setup(lane_idx, target_time, end_time, duration, direction, data.is_lite)
	else:
		note_node.setup(lane_idx, target_time, direction, data.is_lite)

	note_node.tree_exited.connect(func():
		if is_hold: active_hold_notes[mode][lane_idx].erase(note_node)
		else: active_notes[mode][lane_idx].erase(note_node)
	)

	return note_node


# --- FOR PREVIEW ---
func recalculate_note_index(current_beat: float) -> void:
	# despawn all currently active notes, they'll respawn fresh if still relevant
	_clear_all_notes()
	
	note_index = 0
	while note_index < chart_resource.notes.size():
		var data: NoteData = chart_resource.notes[note_index]
		if current_beat < data.beat_start:
			break
		note_index += 1

func _clear_all_notes() -> void:
	for mode in active_notes.keys():
		for lane in range(active_notes[mode].size()):
			for note in active_notes[mode][lane].duplicate():
				if is_instance_valid(note):
					note.queue_free()
			active_notes[mode][lane].clear()

	for mode in active_hold_notes.keys():
		for lane in range(active_hold_notes[mode].size()):
			for note in active_hold_notes[mode][lane].duplicate():
				if is_instance_valid(note):
					note.queue_free()
			active_hold_notes[mode][lane].clear()
