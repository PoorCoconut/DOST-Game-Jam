extends Node2D

@export_group("Note Scenes")
@export var note_scene: PackedScene
@export var hold_note_scene: PackedScene

@export_group("Chart Stats")
@export var spawn_ahead_beats: float = 4.0 
@export var scroll_speed: float = 600.0

var chart_resource: Resource = load("res://systems/components/chart/Geoxor - Lollipop.tres")

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
	Conductor.load_song(chart_resource)
	chart_resource.notes.sort_custom(func(a, b): return a.beat_start < b.beat_start)
	Conductor.play_song()

func _process(_delta: float) -> void:
	if chart_resource == null: return
	
	var current_beat = Conductor.get_beat()

	while note_index < chart_resource.notes.size():
		var data: NoteData = chart_resource.notes[note_index]
		
		if current_beat >= data.beat_start - spawn_ahead_beats:
			spawn_note(data)
			note_index += 1
		else:
			break

func spawn_note(data: NoteData) -> void:
	var lane = data.lane
	var mode = "+" if data.mode.contains("+") else "x"
	var angles = plus_angles if mode == "+" else x_angles
	
	var angle_rad = deg_to_rad(angles[lane])
	var direction = Vector2(cos(angle_rad), sin(angle_rad))

	if data.beat_end > data.beat_start:
		# hold note
		var hold = hold_note_scene.instantiate()
		add_child(hold)
		var target_time = data.beat_start * Conductor.seconds_per_beat
		var end_time = data.beat_end * Conductor.seconds_per_beat
		var beat_duration = data.beat_end - data.beat_start
		hold.scroll_speed = scroll_speed
		hold.setup(data.lane, target_time, end_time, beat_duration, direction)
		active_hold_notes[mode][lane].append(hold)
		hold.tree_exited.connect(func(): active_hold_notes[mode][lane].erase(hold))
	else:
		# tap note
		var new_note = note_scene.instantiate()
		add_child(new_note)
		var target_time = data.beat_start * Conductor.seconds_per_beat
		new_note.setup(data.lane, target_time, direction)
		active_notes[mode][lane].append(new_note)
		new_note.tree_exited.connect(func(): active_notes[mode][lane].erase(new_note))
