@tool
extends Node2D

@onready var title_label: Label = $UI/SongInfo/TitleLabel
@onready var bpm_label: Label = $UI/SongInfo/BPMLabel
@onready var bpm_field: LineEdit = $UI/BPMField
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var grid_view: Control = $UI/ScrollContainer/GridView  # adjust path to match your tree
@onready var file_dialog: FileDialog = $UI/FileButtons/SongFileDialog
@onready var scroll_container: ScrollContainer = $UI/ScrollContainer
@onready var scrubber: Control = $UI/Scrubber  # must have the song_scrubber.gd script
@onready var chart_file_dialog: FileDialog = $UI/FileButtons/ChartFileDialog
@onready var mode_label: Label = $UI/SongInfo/ModeLabel
@onready var snap_option: OptionButton = $UI/FileButtons/SnapOption
@onready var lane_headers: Array[Label] = [
	$UI/GridHeader/North,
	$UI/GridHeader/East,
	$UI/GridHeader/South,
	$UI/GridHeader/West,
]

const LOW_LABELS := ["        North      |", "      East       |", "    South     ", "|      West"]
const HIGH_LABELS := ["   North-East ", "|North-West|", " South-East", "| South-West"]

var is_paused: bool = false
var paused_position: float = 0.0
var chart: ChartData

func _ready() -> void:
	snap_option.add_item("1/1", 1)
	snap_option.add_item("1/2 (halves)", 2)
	snap_option.add_item("1/3 (thirds)", 3)
	snap_option.add_item("1/4 (fourths)", 4)
	snap_option.add_item("1/5 (fifths)", 5)
	snap_option.add_item("1/6 (sixths)", 6)
	snap_option.add_item("1/8 (eighths)", 8)
	snap_option.select(3)  # default to 1/4
	new_chart()

func _on_snap_option_item_selected(index: int) -> void:
	var divisor: int = snap_option.get_item_id(index)
	grid_view.snap_divisor = divisor
	grid_view.queue_redraw()

func _process(_delta: float) -> void:
	if audio_player.playing and not audio_player.stream_paused:
		var t := audio_player.get_playback_position()
		grid_view.update_playhead(t)
		scrubber.update_progress(t)
		_sync_scroll_to_beat(grid_view.playhead_beat)

func _on_scrubber_seek_requested(time_seconds: float) -> void:
	paused_position = time_seconds
	scrubber.update_progress(time_seconds)  # ← immediate visual feedback, don't wait for _process
	if is_paused or not audio_player.playing:
		grid_view.update_playhead(time_seconds)
		_sync_scroll_to_beat(grid_view.playhead_beat)
	else:
		audio_player.play(time_seconds)

func _sync_scroll_to_beat(beat: float) -> void:
	scroll_container.scroll_vertical = int(beat * grid_view.pixels_per_beat) - 500
	
func refresh_song_info() -> void:
	title_label.text = "Title: %s" % chart.song_name
	bpm_label.text = "BPM: %.1f" % chart.bpm

func _on_bpm_field_text_changed(new_text: String) -> void:
	var value := new_text.to_float()
	if value <= 0 or not new_text.is_valid_float():
		bpm_field.modulate = Color.RED  # invalid/incomplete — visually obvious
		return

	bpm_field.modulate = Color.WHITE  # valid — reset to normal
	chart.bpm = value
	grid_view.update_content_size()
	bpm_label.text = "BPM: %.1f" % value

func new_chart() -> void:
	chart = ChartData.new()
	chart.song_name = "untitled"
	chart.bpm = 120.0
	grid_view.chart = chart
	grid_view.queue_redraw()
	refresh_song_info()
	mode_label.text = "Mode: low (+)"
	_update_lane_headers("low (+)")

func load_song(path: String) -> void:
	var stream: AudioStream = load(path)
	chart.stream = stream
	chart.song_name = path.get_file().get_basename()
	audio_player.stream = stream
	grid_view.update_content_size()
	refresh_song_info()
	scrubber.duration = stream.get_length()

func save_chart() -> void:
	chart.sort_notes()
	var dir := "res://systems/components/chart/"
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_absolute(dir)
	var err := ResourceSaver.save(chart, dir + chart.song_name + ".tres")
	if err == OK:
		print("Saved: ", chart.song_name)
	else:
		print("Save failed: ", err)

func _on_mode_toggle_pressed() -> void:
	var new_mode := "high (x)" if grid_view.current_mode == "low (+)" else "low (+)"
	grid_view.set_mode(new_mode)

func _on_load_chart_pressed() -> void:
	var abs_path := ProjectSettings.globalize_path("res://systems/components/chart/")
	chart_file_dialog.current_dir = abs_path
	chart_file_dialog.popup_centered()

func _on_chart_file_dialog_file_selected(path: String) -> void:
	var loaded: ChartData = load(path)
	if loaded == null:
		print("Failed to load chart at: ", path)
		return

	chart = loaded
	grid_view.chart = chart
	grid_view.update_content_size()
	refresh_song_info()

	if chart.stream:
		audio_player.stream = chart.stream
		scrubber.duration = chart.stream.get_length()
	else:
		print("Warning: chart has no associated stream")

	paused_position = 0.0
	is_paused = false
	mode_label.text = "Mode: low (+)"
	grid_view.set_mode("low (+)")

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

func _on_bpm_field_text_submitted(new_text: String) -> void:
	var value := new_text.to_float()
	if value <= 0:
		return  # ignore garbage input
	chart.bpm = value
	grid_view.update_content_size()  # redraw grid lines since beat spacing depends on bpm

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select"):  # spacebar — play/pause
		_toggle_playback()

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ALT:
			_toggle_mode()

func _toggle_mode() -> void:
	var new_mode := "high (x)" if grid_view.current_mode == "low (+)" else "low (+)"
	grid_view.set_mode(new_mode)
	mode_label.text = "Mode: %s" % new_mode
	mode_label.modulate = Color.ORANGE if new_mode == "high (x)" else Color.CYAN
	_update_lane_headers(new_mode)

func _update_lane_headers(mode: String) -> void:
	var labels := LOW_LABELS if mode == "low (+)" else HIGH_LABELS
	for i in range(lane_headers.size()):
		lane_headers[i].text = labels[i]

func _toggle_playback() -> void:
	if audio_player.stream == null:
		return
	if is_paused or not audio_player.playing:
		audio_player.play(paused_position)
		is_paused = false
	else:
		paused_position = audio_player.get_playback_position()
		audio_player.stop()
		is_paused = true

func _on_play_pause_pressed() -> void:
	_toggle_playback()
