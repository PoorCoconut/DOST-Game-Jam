@tool
extends Control

@export var chart: ChartData
@export var pixels_per_beat: float = 80.0
@export var lane_count: int = 4
@export var lane_width: float = 100.0
@export var snap_divisor: int = 4  # 1/4 beat snapping

# Notes/Charting
var dragging: bool = false
var drag_lane: int = -1
var drag_start_beat: float = 0.0
var drag_current_beat: float = 0.0
var current_mode: String = "low (+)"
var playhead_beat: float = 0.0
var placing_special: bool = false
# Ring Scale
var selected_ring_event: ScaleEvent = null
var ring_dragging: bool = false
var ring_drag_event: ScaleEvent = null
var ring_drag_start_beat: float = 0.0
var ring_drag_current_beat: float = 0.0
const RING_COLUMN_WIDTH := 60.0
const RING_MIN_PERCENT := 50.0
const RING_MAX_PERCENT := 210.0

signal ring_event_selected(ev: ScaleEvent)

func _ready() -> void:
	update_content_size()


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): 
		return


func update_content_size() -> void:
	var total_beats := 200.0
	if chart and chart.stream and chart.bpm > 0:
		total_beats = chart.stream.get_length() * chart.bpm / 60.0
		Conductor.load_song(chart)
	var total_width := lane_count * lane_width + RING_COLUMN_WIDTH + 20.0
	custom_minimum_size = Vector2(total_width, total_beats * pixels_per_beat + 200)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if chart == null:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		if mb.pressed:
			if _in_ring_column(mb.position.x):
				_handle_ring_press(mb)
				return
			if mb.button_index != MOUSE_BUTTON_LEFT:
				return
			var lane := int(mb.position.x / lane_width)
			if lane < 0 or lane >= lane_count:
				return
			dragging = true
			drag_lane = lane
			drag_start_beat = snap_beat(mb.position.y / pixels_per_beat)
			drag_current_beat = drag_start_beat
		else:
			if ring_dragging:
				_finish_ring_drag()
			elif dragging:
				_finish_drag()
			dragging = false

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if ring_dragging:
			ring_drag_current_beat = max(snap_beat(mm.position.y / pixels_per_beat), ring_drag_start_beat)
			queue_redraw()
		elif dragging:
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
		# real drag — hold note (holds don't use special type for now)
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
		chart.add_note(beat, lane, current_mode, 0.0, placing_special)
	queue_redraw()

func set_mode(mode: String) -> void:
	current_mode = mode
	queue_redraw()

func update_playhead(time_seconds: float) -> void:
	if chart == null or chart.bpm <= 0:
		return
	playhead_beat = time_seconds * chart.bpm / 60.0
	queue_redraw()

# UI
func _draw() -> void:
	_draw_lanes()
	_draw_grid_lines()
	_draw_notes()
	_draw_playhead()
	_draw_ring_events()

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

func _draw_playhead() -> void:
	var y := playhead_beat * pixels_per_beat
	draw_line(Vector2(0, y), Vector2(lane_count * lane_width, y), Color.RED, 2.0)

func _draw_notes() -> void:
	if chart == null:
		return
	for n in chart.notes:
		var x := n.lane * lane_width
		var color: Color
		if n.is_special:
			color = Color(0.7, 0.4, 1.0) # Special note color
		else:
			color = Color.CYAN if n.mode == "low (+)" else Color.ORANGE
			
		if n.beat_end > n.beat_start:
			var y_top := n.beat_start * pixels_per_beat
			var y_bottom := n.beat_end * pixels_per_beat
			draw_rect(Rect2(x + 4, y_top, lane_width - 8, y_bottom - y_top), color * Color(1, 1, 1, 0.5))
			draw_rect(Rect2(x + 4, y_top - 4, lane_width - 8, 8), color)
		else:
			var y := n.beat_start * pixels_per_beat
			draw_rect(Rect2(x + 4, y - 4, lane_width - 8, 8), color)

	if dragging:
		var x := drag_lane * lane_width
		var y_top = min(drag_start_beat, drag_current_beat) * pixels_per_beat
		var y_bottom = max(drag_start_beat, drag_current_beat) * pixels_per_beat
		draw_rect(Rect2(x + 4, y_top, lane_width - 8, max(y_bottom - y_top, 1)), Color(1, 1, 1, 0.3))

func _draw_ring_events() -> void:
	if chart == null:
		return
	var x := _ring_column_x() + RING_COLUMN_WIDTH / 2.0

	for ev in chart.scale_events:
		if ring_dragging and ev == ring_drag_event:
			continue
		_draw_single_ring_event(ev.beat, ev.duration_beats, ev.target_scale, x, ev == selected_ring_event)

	if ring_dragging and ring_drag_event:
		var live_duration = max(ring_drag_current_beat - ring_drag_start_beat, 0.0)
		_draw_single_ring_event(ring_drag_start_beat, live_duration, ring_drag_event.target_scale, x, true)

func _draw_single_ring_event(beat: float, duration_beats: float, target_scale: float, x: float, is_selected: bool) -> void:
	var y_head := beat * pixels_per_beat
	var y_tail := (beat + duration_beats) * pixels_per_beat
	var color := Color.YELLOW if is_selected else Color(0.7, 0.4, 1.0)

	if y_tail > y_head:
		draw_line(Vector2(x, y_head), Vector2(x, y_tail), Color(color.r, color.g, color.b, 0.5), 4.0)
		draw_circle(Vector2(x, y_tail), 5, color)

	draw_circle(Vector2(x, y_head), 8, color)
	draw_string(ThemeDB.fallback_font, Vector2(x + 12, y_head + 4), "%.0f%%" % (target_scale * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

# Ring Scaler
func _in_ring_column(x: float) -> bool:
	var col_x := _ring_column_x()
	return x >= col_x and x <= col_x + RING_COLUMN_WIDTH

func _handle_ring_press(mb: InputEventMouseButton) -> void:
	var beat := snap_beat(mb.position.y / pixels_per_beat)

	if mb.button_index == MOUSE_BUTTON_RIGHT:
		var existing := chart.get_scale_event_at(beat)
		if existing:
			if selected_ring_event == existing:
				selected_ring_event = null
				ring_event_selected.emit(null)
			chart.remove_scale_event(existing)
			queue_redraw()
		return

	if mb.button_index != MOUSE_BUTTON_LEFT:
		return

	var existing := chart.get_scale_event_at(beat)
	if existing:
		ring_dragging = true
		ring_drag_event = existing
		ring_drag_start_beat = existing.beat
		ring_drag_current_beat = existing.beat + existing.duration_beats
		selected_ring_event = existing
	else:
		var new_event := chart.add_scale_event(beat, 1.0, 0.0)
		ring_dragging = true
		ring_drag_event = new_event
		ring_drag_start_beat = beat
		ring_drag_current_beat = beat
		selected_ring_event = new_event

	ring_event_selected.emit(selected_ring_event)
	queue_redraw()

func _finish_ring_drag() -> void:
	if ring_drag_event:
		ring_drag_event.duration_beats = max(ring_drag_current_beat - ring_drag_start_beat, 0.0)
	ring_dragging = false
	ring_drag_event = null
	queue_redraw()

func _ring_column_x() -> float:
	return lane_count * lane_width + 10.0

func set_ring_event_percent(percent: float) -> void:
	if selected_ring_event == null:
		return
	var clamped = clamp(percent, RING_MIN_PERCENT, RING_MAX_PERCENT)
	selected_ring_event.target_scale = clamped / 100.0
	queue_redraw()
