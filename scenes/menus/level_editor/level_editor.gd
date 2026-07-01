extends Node2D

# Info Labels
@onready var title_label: Label = $UI/SongInfo/TitleLabel
@onready var bpm_label: Label = $UI/SongInfo/BPMLabel
@onready var bpm_field: LineEdit = $UI/BPMField
@onready var mode_label: Label = $UI/SongInfo/ModeLabel

# Editor Essentials
@onready var grid_view: Control = $UI/ScrollContainer/GridView
@onready var scroll_container: ScrollContainer = $UI/ScrollContainer
@onready var scrubber: Control = $UI/Scrubber
@onready var snap_option: OptionButton = $UI/FileButtons/SnapOption
@onready var lane_headers: Array[Label] = [
	$UI/GridHeader/North,
	$UI/GridHeader/East,
	$UI/GridHeader/South,
	$UI/GridHeader/West,
]

const LOW_LABELS := ["        North      |", "      East       |", "    South     ", "|      West"]
const HIGH_LABELS := ["   North-East ", "|South-East |", "South-West", "| North-West"]

# Live note-capture keybinds.
const LANE_KEYS := {
	KEY_F: 0, # North
	KEY_K: 1, # East
	KEY_J: 2, # South
	KEY_D: 3, # West
}

# Offset calibration keybinds.
# [ / ] = nudge offset by a fixed step. Hold Shift for a finer 1ms step. But doesn't work. Dead weight. maybe
const OFFSET_SET_KEY := KEY_O
const OFFSET_NUDGE_STEP := 0.01
const OFFSET_NUDGE_STEP_FINE := 0.001

var is_paused: bool = false
var paused_position: float = 0.0
var chart: ChartData
var _removed_accept_events: Array[InputEvent] = []

# Ring Scaler
@onready var ring_percent_field: LineEdit = $UI/RingPercentField  # adjust path

# File Handlers
@onready var chart_file_dialog: FileDialog = $UI/FileButtons/ChartFileDialog
@onready var file_dialog: FileDialog = $UI/FileButtons/SongFileDialog

# Gameplay Preview 
@onready var preview_viewport: SubViewport = $UI/PreviewPanel/SubViewportContainer/PreviewViewport
const GAMEPLAY_SCENE := preload(SceneManager.GAMEPLAY_DIR)
var preview_instance: Node = null


func _ready() -> void:
	for evt in InputMap.action_get_events("ui_accept"):
		if evt is InputEventKey and (evt.physical_keycode == KEY_SPACE or evt.keycode == KEY_SPACE):
			InputMap.action_erase_event("ui_accept", evt)
			_removed_accept_events.append(evt)
	
	snap_option.clear()
	snap_option.add_item("1/1", 1)
	snap_option.add_item("1/2 (halves)", 2)
	snap_option.add_item("1/3 (thirds)", 3)
	snap_option.add_item("1/4 (fourths)", 4)
	snap_option.add_item("1/5 (fifths)", 5)
	snap_option.add_item("1/6 (sixths)", 6)
	snap_option.add_item("1/8 (eighths)", 8)
	snap_option.select(3)  # default to 1/4
	new_chart()
	
	grid_view.seek_requested.connect(_on_scrubber_seek_requested)
	grid_view.ring_event_selected.connect(_on_ring_event_selected)
	ring_percent_field.editable = false
	ring_percent_field.placeholder_text = "Set Ring Scale"


func _exit_tree() -> void:
	for evt in _removed_accept_events:
		InputMap.action_add_event("ui_accept", evt)


func _process(_delta: float) -> void:
	if Conductor.audio_player.playing and not is_paused:
		var t := Conductor.get_time()
		grid_view.update_playhead(t)
		scrubber.update_progress(t)
		_sync_scroll_to_beat(grid_view.playhead_beat)


# Song Info
func refresh_song_info() -> void:
	title_label.text = "Title: %s" % chart.song_name
	bpm_label.text = "BPM: %.1f" % chart.bpm


func _on_bpm_field_text_changed(new_text: String) -> void:
	var value := new_text.to_float()
	if value <= 0 or not new_text.is_valid_float():
		bpm_field.modulate = Color.RED
		return
	
	bpm_field.modulate = Color.WHITE
	chart.bpm = value
	Conductor.update_song_bpm(value)
	grid_view.update_content_size()
	bpm_label.text = "BPM: %.1f" % value


# Timeline Manager thingy
func _on_scrubber_seek_requested(time_seconds: float) -> void:
	paused_position = time_seconds
	scrubber.update_progress(time_seconds)
	if is_paused or not Conductor.audio_player.playing:
		grid_view.update_playhead(time_seconds)
		_sync_scroll_to_beat(grid_view.playhead_beat)
	else:
		Conductor.audio_player.play(time_seconds)

	if preview_instance:
		var spawner := preview_instance.get_node("PlayfieldContainer/NoteMask/NoteSpawner")
		var ring := preview_instance.get_node("PlayfieldContainer")
		if spawner:
			spawner.recalculate_note_index(Conductor.time_to_beat(time_seconds))
		if ring:
			ring.recalculate_for_beat(Conductor.time_to_beat(time_seconds))


func _sync_scroll_to_beat(beat: float) -> void:
	scroll_container.scroll_vertical = int(beat * grid_view.pixels_per_beat) - 500


# Basic Functions (New Chart, Load Song, Save Chart, Load Chart)
func new_chart() -> void:
	chart = ChartData.new()
	chart.song_name = "untitled"
	chart.bpm = 120.0
	chart.offset = 0.0
	grid_view.chart = chart
	grid_view.queue_redraw()
	refresh_song_info()
	mode_label.text = "Mode: low (+)"
	_update_lane_headers("low (+)")
	_refresh_preview()


func load_song(path: String) -> void:
	var stream: AudioStream = load(path)
	chart.stream = stream
	chart.song_name = path.get_file().get_basename()
	Conductor.load_song(chart)
	grid_view.update_content_size()
	refresh_song_info()
	scrubber.duration = stream.get_length()
	_refresh_preview()


func save_chart() -> void:
	chart.sort_notes()
	
	# FOR DEBUG
	# change to /tests/ instead of /actual/
	var dir := "res://scenes/levels/actual/"
	
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_absolute(dir)
	var err := ResourceSaver.save(chart, dir + chart.song_name + ".tres")
	if err == OK:
		print("Saved: ", chart.song_name)
	else:
		print("Save failed: ", err)


# Chart Editor (Lane Headers, File Handling, Grid Snapping, BPM Setting, Ring Scaling)
func _update_lane_headers(mode: String) -> void:
	var labels := LOW_LABELS if mode == "low (+)" else HIGH_LABELS
	for i in range(lane_headers.size()):
		lane_headers[i].text = labels[i]


func _on_chart_file_dialog_file_selected(path: String) -> void:
	var loaded: ChartData = load(path)
	if loaded == null:
		print("[ERROR] LevelEditor: failed to load chart at: ", path)
		return
	
	chart = loaded
	grid_view.chart = chart
	grid_view.update_content_size()
	refresh_song_info()
	bpm_field.text = "%.1f" % chart.bpm
	bpm_field.modulate = Color.WHITE

	if chart.stream:
		Conductor.load_song(chart)
		scrubber.duration = chart.stream.get_length()
	else:
		print("[ERROR] LevelEditor: chart has no associated stream")
	
	paused_position = 0.0
	is_paused = false
	mode_label.text = "Mode: low (+)"
	grid_view.set_mode("low (+)")
	_refresh_preview()


func _on_snap_option_item_selected(index: int) -> void:
	var divisor: int = snap_option.get_item_id(index)
	grid_view.snap_divisor = divisor
	grid_view.queue_redraw()


func _on_load_chart_pressed() -> void:
	var abs_path := ProjectSettings.globalize_path("res://scenes/")
	chart_file_dialog.current_dir = abs_path
	chart_file_dialog.popup_centered()


func _on_bpm_field_text_submitted(new_text: String) -> void:
	_on_bpm_field_text_changed(new_text)


# Button Controls
func _on_new_chart_pressed() -> void:
	new_chart()


func _on_save_chart_pressed() -> void:
	save_chart()


func _on_load_song_pressed() -> void:
	var abs_path := ProjectSettings.globalize_path("res://sound/music/")
	file_dialog.current_dir = abs_path
	file_dialog.popup_centered()


func _on_song_file_dialog_file_selected(path: String) -> void:
	load_song(path)


# Mode Control (High or Low)
func _on_mode_toggle_pressed() -> void:
	var new_mode := "high (x)" if grid_view.current_mode == "low (+)" else "low (+)"
	grid_view.set_mode(new_mode)


func _toggle_mode() -> void:
	if grid_view:
		grid_view.placing_special = false # Turn off special when switching lane axes
	var new_mode := "high (x)" if grid_view.current_mode == "low (+)" else "low (+)" 
	grid_view.set_mode(new_mode) 
	mode_label.text = "Mode: %s" % new_mode 
	mode_label.modulate = Color.ORANGE if new_mode == "high (x)" else Color.CYAN 
	_update_lane_headers(new_mode)


# Audio Control (Pause and Play)
func _toggle_playback() -> void:
	if Conductor.active_chart == null:
		return
	if is_paused or not Conductor.audio_player.playing:
		Conductor.audio_player.play(paused_position)
		is_paused = false
	else:
		paused_position = Conductor.get_time()
		Conductor.audio_player.stop()
		is_paused = true



func _input(event: InputEvent) -> void:
	# If a text field has focus, let it handle all keys untouched —
	# stops Backspace/Ctrl+C/Ctrl+V/letter-keys from also triggering editor shortcuts.
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return

	# Handle Spacebar (UI Select) separately
	if event.is_action_pressed("ui_select"):
		_toggle_playback()
		return

	# Handle Key Events
	if event is InputEventKey and event.pressed and not event.echo:
		
		# Handle CTRL Shortcuts first
		if event.ctrl_pressed:
			match event.keycode:
				KEY_C: grid_view.copy_selected()
				KEY_V: grid_view.paste_at_anchor()
				KEY_Z: grid_view.undo()
				KEY_Y: grid_view.redo()
			return # Exit early if a Ctrl combo was handled

		# Handle everything else
		match event.keycode:
			KEY_ALT: 
				_toggle_mode()
			
			OFFSET_SET_KEY: 
				_calibrate_offset()
			
			KEY_BRACKETLEFT, KEY_BRACKETRIGHT:
				_handle_nudge(event)
				
			KEY_ESCAPE: 
				grid_view.deselect_notes()
			
			KEY_DELETE, KEY_BACKSPACE: 
				grid_view.delete_selected()
			
			KEY_X:
				grid_view.clear_clipboard()
			
			_: # default case
				if LANE_KEYS.has(event.keycode):
					_place_note_live(LANE_KEYS[event.keycode])


# Helper function for offset nudge
func _handle_nudge(event: InputEventKey):
	var step = OFFSET_NUDGE_STEP_FINE if event.shift_pressed else OFFSET_NUDGE_STEP
	var direction = -1 if event.keycode == KEY_BRACKETLEFT else 1
	_nudge_offset(direction * step)


func _place_note_live(lane: int) -> void:
	if chart == null or not Conductor.audio_player.playing:
		return
	var raw_beat: float = Conductor.time_to_beat(Conductor.get_time())
	var beat: float = grid_view.snap_beat(raw_beat)
	chart.add_note(beat, lane, grid_view.current_mode)
	grid_view.queue_redraw()


func _calibrate_offset() -> void:
	if chart == null or not Conductor.audio_player.playing:
		return
	chart.offset = Conductor.get_time()
	Conductor.offset = chart.offset
	grid_view.flash_offset_feedback()
	print("[OFFSET] Set to %.3fs" % chart.offset)


func _nudge_offset(delta: float) -> void:
	if chart == null:
		return
	chart.offset += delta
	Conductor.offset = chart.offset
	grid_view.flash_offset_feedback()
	print("[OFFSET] Now %.3fs" % chart.offset)


func _on_play_pause_pressed() -> void:
	_toggle_playback()


func _on_preview_restart_pressed() -> void:
	paused_position = 0.0
	Conductor.play_song()
	is_paused = false
	if preview_instance:
		var spawner := preview_instance.get_node("PlayfieldContainer/NoteMask/NoteSpawner")
		var ring := preview_instance.get_node("PlayfieldContainer")
		if spawner:
			spawner.recalculate_note_index(0.0)
		if ring:
			ring.reset_to_default()


# Ring Scaler
func _on_ring_event_selected(ev: ScaleEvent) -> void:
	if ev == null:
		ring_percent_field.text = ""
		ring_percent_field.editable = false
	else:
		ring_percent_field.text = "%.0f" % (ev.target_scale * 100.0)
		ring_percent_field.editable = true


func _on_ring_percent_field_text_submitted(new_text: String) -> void:
	if grid_view.selected_ring_event == null:
		ring_percent_field.text = ""
		ring_percent_field.editable = false
		return
	var value := new_text.to_float()
	if value <= 0 or not new_text.is_valid_float():
		return
	grid_view.set_ring_event_percent(value)
	ring_percent_field.text = "%.0f" % (grid_view.selected_ring_event.target_scale * 100.0)


func _refresh_preview() -> void:
	if preview_instance:
		preview_instance.queue_free()
		preview_instance = null
	
	if chart == null or chart.stream == null:
		return
	
	SceneManager.selected_chart = chart
	preview_instance = GAMEPLAY_SCENE.instantiate()
	
	var spawner := preview_instance.get_node("PlayfieldContainer/NoteMask/NoteSpawner")
	if spawner:
		spawner.is_preview = true
	
	var judge := preview_instance.get_node("Judge")
	if judge:
		judge.autoplay = true
	
	preview_viewport.add_child(preview_instance)

# Ring Scaler
func _on_ring_event_selected(ev: ScaleEvent) -> void:
	if ev == null:
		ring_percent_field.text = ""
		ring_percent_field.editable = false
	else:
		ring_percent_field.text = "%.0f" % (ev.target_scale * 100.0)
		ring_percent_field.editable = true

func _on_ring_percent_field_text_submitted(new_text: String) -> void:
	if grid_view.selected_ring_event == null:
		ring_percent_field.text = ""
		ring_percent_field.editable = false
		return
	var value := new_text.to_float()
	if value <= 0 or not new_text.is_valid_float():
		return
	grid_view.set_ring_event_percent(value)
	ring_percent_field.text = "%.0f" % (grid_view.selected_ring_event.target_scale * 100.0)
