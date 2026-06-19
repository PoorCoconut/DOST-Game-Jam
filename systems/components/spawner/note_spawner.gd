extends Node2D

@export var note_scene: PackedScene
@export var chart_resource: Resource
@export var spawn_ahead_beats: float = 4.0 
@export var scroll_speed: float = 600.0

# (+): N, E, S, W | (x): NE, SE, SW, NW
var plus_angles: Array = [-90.0, 0.0, 90.0, 180.0]
var x_angles: Array = [-45.0, 45.0, 135.0, 225.0]

var active_notes: Dictionary = {
	"+": [[], [], [], []],
	"x": [[], [], [], []],
}

var note_index: int = 0

func _ready():
	Conductor.load_song(chart_resource)
	chart_resource.notes.sort_custom(func(a, b): return a.beat < b.beat)
	Conductor.play_song()

func _process(_delta: float) -> void:
	if chart_resource == null: return
	
	var current_beat = Conductor.get_beat()

	while note_index < chart_resource.notes.size():
		var data: NoteData = chart_resource.notes[note_index]
		
		if current_beat >= data.beat - spawn_ahead_beats:
			spawn_note(data)
			note_index += 1
		else:
			break

func spawn_note(data: NoteData) -> void:
	var new_note = note_scene.instantiate()
	var lane = data.lane
	var mode = "+" if data.mode.contains("+") else "x"
	var angles = plus_angles if mode == "+" else x_angles
	
	var angle_rad = deg_to_rad(angles[lane])
	var direction = Vector2(cos(angle_rad), sin(angle_rad))
	
	add_child(new_note)
	var target_time = data.beat * Conductor.seconds_per_beat
	new_note.setup(data.lane, target_time, direction)
	
	active_notes[mode][lane].append(new_note)
	new_note.tree_exited.connect(func(): active_notes[mode][lane].erase(new_note))
