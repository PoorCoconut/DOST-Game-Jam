extends Node2D

@export_group("Note Scenes")
@export var note_scene: PackedScene
@export var hold_note_scene: PackedScene
@export var special_note_scene: PackedScene

@export_group("Chart Stats")
@export var spawn_ahead_beats: float = 4.0 
@export var scroll_speed: float = 600.0

# --- FOR PREVIEW ---
@export var is_preview: bool = false

var chart_resource: Resource

# (+): N, E, S, W | (x): NE, SE, SW, NW
var plus_angles: Array = [-90.0, 0.0, 90.0, 180.0]
var x_angles: Array = [-45.0, 45.0, 135.0, 225.0]

# Clockwise:   -45, 45, 135, 225
# Counterwise: -135, -45, 45, 135

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
	Conductor.load_song(chart_resource)
	
	var bg := get_node_or_null("%CoverBackground")
	if bg and chart_resource.background:
		bg.texture = chart_resource.background
		bg.visible = true
		bg.global_position = get_viewport_rect().size / 2.0

	# --- FOR PREVIEW ---
	if not is_preview:
		Conductor.play_song()


func _process(_delta: float) -> void:
	if chart_resource == null:
		return

	var current_beat: float = Conductor.get_beat()
	var beat_groups = {}

	while note_index < chart_resource.notes.size():
		var data: NoteData = chart_resource.notes[note_index]
		
		if current_beat >= data.beat_start - spawn_ahead_beats:
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
	
	# SYNC LOGIC
	# if two or more notes spawn in the same beat, highlight them
	for b in beat_groups:
		var group = beat_groups[b]
		if group.size() > 1:
			VisualEffects.apply_sync_visuals(group)


func spawn_note(data: NoteData) -> Node2D:
	# capture data immediately to avoid reference issues
	var lane_idx = data.lane
	var is_hold = data.is_hold_note()

	# calculate direction
	var mode = data.mode_type()
	var angles = plus_angles if mode == "+" else x_angles
	var angle_rad = deg_to_rad(angles[lane_idx])
	var direction = Vector2(cos(angle_rad), sin(angle_rad))

	var note_node
	if data.is_special:
		note_node = special_note_scene.instantiate()
	elif is_hold:
		# hold note
		note_node = hold_note_scene.instantiate()
		active_hold_notes[mode][lane_idx].append(note_node)
	else:
		# tap note
		note_node = note_scene.instantiate()
		active_notes[mode][lane_idx].append(note_node)

	# instantiate
	get_parent().add_child(note_node)

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

# --- FOR PREVIEW ---
func recalculate_note_index(current_beat: float) -> void:
	# despawn all currently active notes — they'll respawn fresh if still relevant
	_clear_all_notes()

	# find the correct index: first note whose spawn window hasn't passed yet
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
