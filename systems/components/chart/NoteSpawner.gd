extends Node

@export var note_scene: PackedScene
@export var chart: Resource

@onready var note_container: Node2D = $NoteContainer
@onready var lane_positions = [$Lane0, $Lane1, $Lane2, $Lane3]

var note_index := 0
var spawn_ahead_beats := 4.0 # How many beats in advance to spawn a note

func _process(_delta):
	if chart == null: return
	
	var current_beat = Conductor.song_position / Conductor.seconds_per_beat
	
	if note_index < chart.notes.size():
		var next_note_data = chart.notes[note_index]
		
		# If the song is almost at the note's time (minus the lead-in)
		if current_beat >= next_note_data.beat - spawn_ahead_beats:
			spawn_note(next_note_data)
			note_index += 1

func spawn_note(data):
	var new_note = note_scene.instantiate()
	
	# 1. Tell the note when it needs to be hit
	new_note.target_beat = data.beat
	new_note.lane = data.lane
	
	# 2. Position it horizontally based on its lane
	var lane_node = lane_positions[data.lane]
	new_note.position.x = lane_node.position.x
	
	# 3. Add it to the world
	note_container.add_child(new_note)
