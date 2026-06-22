extends Node2D

@export_group("Note Scenes")
@export var note_scene: PackedScene
@export var hold_note_scene: PackedScene

@export_group("Chart Stats")
@export var spawn_ahead_beats: float = 4.0 
@export var scroll_speed: float = 600.0

var chart_resource: Resource = SceneManager.selected_chart

# (+): N, E, S, W | (x): NE, SE, SW, NW
var plus_angles: Array = [-90.0, 0.0, 90.0, 180.0]
var x_angles: Array = [-45.0, 45.0, 135.0, 225.0]

var active_notes: Dictionary = {
	"+": [[], [], [], []],
	"x": [[], [], [], []],
}

# hold notes tracked separately so judge.gd can handle release events
var active_hold_notes: Dictionary = {
	"+": [[], [], [], []],
	"x": [[], [], [], []],
}

var note_index: int = 0

func _ready():
	# ensures that notes are chronological according to beat
	chart_resource.notes.sort_custom(
		func(a, b): return a.beat_start < b.beat_start
	)
	
	Conductor.load_song(chart_resource)
	Conductor.play_song()

func _process(_delta: float) -> void:
	if chart_resource == null: return
	
	var current_beat: float = Conductor.get_beat()
	var spawned_this_frame = []

	while note_index < chart_resource.notes.size():
		var data: NoteData = chart_resource.notes[note_index]
		
		if current_beat >= data.beat_start - spawn_ahead_beats:
			var note = spawn_note(data)
			spawned_this_frame.append(note)
			note_index += 1
		else:
			break
	
	# if two or more notes spawn in the same beat (sync note)
	# put logic here

func spawn_note(data: NoteData) -> Node2D:
	# FIX: reorganized the logic here, so lane conflicts never happen
	
	# capture data immediately to avoid reference issues
	var lane_idx = data.lane
	var is_hold = data.beat_end > data.beat_start

	# calculate direction
	var mode = "+" if data.mode.contains("+") else "x"
	var angles = plus_angles if mode == "+" else x_angles
	var angle_rad = deg_to_rad(angles[lane_idx])
	var direction = Vector2(cos(angle_rad), sin(angle_rad))

	var note_node
	if is_hold:
		# hold note
		note_node = hold_note_scene.instantiate()
		active_hold_notes[mode][lane_idx].append(note_node)
	else:
		# tap note
		note_node = note_scene.instantiate()
		active_notes[mode][lane_idx].append(note_node)

	# instantiate
	add_child(note_node)

	# setup note
	var target_time = data.beat_start * Conductor.seconds_per_beat
	if is_hold:
		# hold note setup
		var end_time = data.beat_end * Conductor.seconds_per_beat
		var duration = data.beat_end - data.beat_start
		note_node.setup(lane_idx, target_time, end_time, duration, direction)
	else:
		# tap note setup
		note_node.setup(lane_idx, target_time, direction)

	note_node.tree_exited.connect(func(): 
		if is_hold: active_hold_notes[mode][lane_idx].erase(note_node)
		else: active_notes[mode][lane_idx].erase(note_node)
	)
	
	return note_node
