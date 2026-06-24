@tool
extends Control

@export var chart: ChartData
@export var pixels_per_beat: float = 80.0
@export var lane_count: int = 4
@export var lane_width: float = 100.0
@export var snap_divisor: int = 4  # 1/4 beat snapping

var dragging: bool = false
var drag_lane: int = -1
var drag_start_beat: float = 0.0
var drag_current_beat: float = 0.0
var current_mode: String = "low (+)"
var playhead_beat: float = 0.0

func _ready() -> void:
	update_content_size()

func update_content_size() -> void:
	var total_beats := 200.0
	if chart and chart.stream and chart.bpm > 0:
		total_beats = chart.stream.get_length() * chart.bpm / 60.0
	custom_minimum_size = Vector2(lane_count * lane_width, total_beats * pixels_per_beat + 200)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if chart == null:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return

		if mb.pressed:
			var lane := int(mb.position.x / lane_width)
			if lane < 0 or lane >= lane_count:
				return
			dragging = true
			drag_lane = lane
			drag_start_beat = snap_beat(mb.position.y / pixels_per_beat)
			drag_current_beat = drag_start_beat
		else:
			if dragging:
				_finish_drag()
			dragging = false

	elif event is InputEventMouseMotion and dragging:
		var mm := event as InputEventMouseMotion
		drag_current_beat = snap_beat(mm.position.y / pixels_per_beat)
		queue_redraw()

func _finish_drag() -> void:
	var beat_start = min(drag_start_beat, drag_current_beat)
	var beat_end = max(drag_start_beat, drag_current_beat)
	
	if beat_start < 0:
		return

	if beat_end - beat_start < (1.0 / snap_divisor):
		# negligible drag — treat as tap note
		_place_or_remove_note(beat_start, drag_lane)
	else:
		# real drag — hold note
		var existing := chart.get_note_at(beat_start, drag_lane, current_mode)
		if existing:
			chart.remove_note(existing)
		else:
			chart.add_note(beat_start, drag_lane, current_mode, beat_end)
	queue_redraw()

func snap_beat(raw_beat: float) -> float:
	var step := 1.0 / snap_divisor
	return round(raw_beat / step) * step

func _place_or_remove_note(beat: float, lane: int) -> void:
	var existing := chart.get_note_at(beat, lane, current_mode)
	if existing:
		chart.remove_note(existing)
	else:
		chart.add_note(beat, lane, current_mode)
	queue_redraw()

func set_mode(mode: String) -> void:
	current_mode = mode
	queue_redraw()

func update_playhead(time_seconds: float) -> void:
	if chart == null or chart.bpm <= 0:
		return
	playhead_beat = time_seconds * chart.bpm / 60.0
	queue_redraw()

func _draw() -> void:
	_draw_lanes()
	_draw_grid_lines()
	_draw_notes()
	_draw_playhead()

func _draw_lanes() -> void:
	for i in range(lane_count + 1):
		var x := i * lane_width
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(1, 1, 1, 0.15), 1.0)

func _draw_grid_lines() -> void:
	if chart == null:
		return
	var total_beats := 200.0
	if chart.stream:
		total_beats = chart.stream.get_length() * chart.bpm / 60.0

	var step := 1.0 / snap_divisor
	var i := 0
	var beat := 0.0
	while beat <= total_beats:
		var y := beat * pixels_per_beat
		var is_downbeat := fmod(beat, 1.0) < 0.001

		var color: Color
		var width: float
		if is_downbeat:
			color = Color(1, 1, 1, 0.9)
			width = 2.0
		else:
			color = Color(1, 1, 1, 0.25)
			width = 1.0

		draw_line(Vector2(0, y), Vector2(lane_count * lane_width, y), color, width)

		# label the subdivision fraction so you can visually confirm snap is correct
		if not is_downbeat:
			var frac_label := "%d/%d" % [i % snap_divisor, snap_divisor]
			draw_string(ThemeDB.fallback_font, Vector2(lane_count * lane_width + 8, y + 4), frac_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1,1,1,0.5))

		i += 1
		beat += step

func _draw_notes() -> void:
	if chart == null:
		return
	for n in chart.notes:
		var x := n.lane * lane_width
		var color := Color.CYAN if n.mode == "low (+)" else Color.ORANGE
		if n.beat_end > n.beat_start:
			var y_top := n.beat_start * pixels_per_beat
			var y_bottom := n.beat_end * pixels_per_beat
			draw_rect(Rect2(x + 4, y_top, lane_width - 8, y_bottom - y_top), color * Color(1, 1, 1, 0.5))
			draw_rect(Rect2(x + 4, y_top - 4, lane_width - 8, 8), color)  # head cap
		else:
			var y := n.beat_start * pixels_per_beat
			draw_rect(Rect2(x + 4, y - 4, lane_width - 8, 8), color)

	# live drag preview
	if dragging:
		var x := drag_lane * lane_width
		var y_top = min(drag_start_beat, drag_current_beat) * pixels_per_beat
		var y_bottom = max(drag_start_beat, drag_current_beat) * pixels_per_beat
		draw_rect(Rect2(x + 4, y_top, lane_width - 8, max(y_bottom - y_top, 1)), Color(1, 1, 1, 0.3))

func _draw_playhead() -> void:
	var y := playhead_beat * pixels_per_beat
	draw_line(Vector2(0, y), Vector2(lane_count * lane_width, y), Color.RED, 2.0)
