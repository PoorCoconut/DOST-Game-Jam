@tool
extends Control

@export var chart: ChartData
@export var pixels_per_beat: float = 80.0
@export var lane_count: int = 4
@export var lane_width: float = 100.0
@export var snap_divisor: int = 4  # 1/4 beat snapping

# Constants for shortcuts and undo/redo
# UNDO: CTRL+Z
# REDO: CTRL+Y
const NOTE_HIT_TOLERANCE_PX := 10.0
const RESIZE_HANDLE_TOLERANCE_PX := 8.0
const ZOOM_STEP := 10.0
const MIN_PIXELS_PER_BEAT := 20.0
const MAX_PIXELS_PER_BEAT := 300.0
const MAX_UNDO_HISTORY := 100

# Note Adding
var dragging: bool = false
var drag_lane: int = -1
var drag_start_beat: float = 0.0
var drag_current_beat: float = 0.0
var current_mode: String = "low (+)"
var playhead_beat: float = 0.0

# Selection
var selecting: bool = false
var select_start: Vector2 = Vector2.ZERO
var select_current: Vector2 = Vector2.ZERO
var selected_notes: Array[NoteData] = []
var clipboard: Array[Dictionary] = []
var last_placed_note: NoteData = null

# Resizing
var resizing: bool = false
var resize_note: NoteData = null
var resize_old_end: float = 0.0

# Undo/Redo
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []

# Offset calibration feedback
var offset_feedback_timer: float = 0.0

signal seek_requested(time_seconds: float)


func _ready() -> void:
	update_content_size()


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): 
		return
	if offset_feedback_timer > 0.0:
		offset_feedback_timer = max(offset_feedback_timer - delta, 0.0)
		queue_redraw()


func update_content_size() -> void:
	var total_beats := 200.0
	if chart and chart.stream and chart.bpm > 0:
		total_beats = chart.stream.get_length() * chart.bpm / 60.0
	custom_minimum_size = Vector2(lane_count * lane_width, total_beats * pixels_per_beat + 200)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if chart == null:
		return
	
	# IF MOUSE CLICK
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		# CTRL + MOUSE SCROLL -> zoom
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			if mb.ctrl_pressed:
				var zoom_dir: float = 1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
				pixels_per_beat = clamp(pixels_per_beat + zoom_dir * ZOOM_STEP, MIN_PIXELS_PER_BEAT, MAX_PIXELS_PER_BEAT)
				update_content_size()
				accept_event()
				return
			else:
				if chart.bpm <= 0:
					return
				var step: float = 1.0 / snap_divisor
				var direction: float = -1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
				var max_beat: float = INF
				if chart.stream:
					max_beat = chart.stream.get_length() * chart.bpm / 60.0
				var new_beat: float = clamp(playhead_beat + direction * step, 0.0, max_beat)
				var new_time: float = Conductor.beat_to_time(new_beat)
				seek_requested.emit(new_time)
				accept_event()
				return
		
		# SHIFT + MOUSE BUTTON (select)
		if mb.pressed and mb.shift_pressed:
				selecting = true
				select_start = mb.position
				select_current = mb.position
				selected_notes.clear()
				queue_redraw()
				return
		
		# NOT MOUSE LEFT (no use for right)
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		
		# MOUSE CLICK/HOLD
		if mb.pressed:
			# not within the correct grid
			var lane := int(mb.position.x / lane_width)
			if lane < 0 or lane >= lane_count:
				return
			
			var raw_beat := mb.position.y / pixels_per_beat
			
			# for resizing tail
			var resize_target := _find_resize_handle(raw_beat, lane)
			if resize_target:
				resizing = true
				resize_note = resize_target
				resize_old_end = resize_target.beat_end
				return
			
			# for deleting a note (undo/redo)
			var existing := _find_note_near(raw_beat, lane, current_mode)
			if existing:
				var removed_note := existing
				chart.remove_note(removed_note)
				if last_placed_note == removed_note:
					last_placed_note = null
				var undo_fn := func():
					chart.notes.append(removed_note)
					chart.sort_notes()
				var redo_fn := func():
					chart.remove_note(removed_note)
				_push_undo(undo_fn, redo_fn)
				queue_redraw()
				return
			
			dragging = true
			drag_lane = lane
			drag_start_beat = snap_beat(mb.position.y / pixels_per_beat)
			drag_current_beat = drag_start_beat
		else:
			if selecting:
				_finish_select()
			elif dragging:
				_finish_drag()
			elif resizing:
				var note := resize_note
				var old_end: float = resize_old_end
				var new_end: float = note.beat_end
				if not is_equal_approx(old_end, new_end):
					var undo_fn := func(): note.beat_end = old_end
					var redo_fn := func(): note.beat_end = new_end
					_push_undo(undo_fn, redo_fn)
			selecting = false
			dragging = false
			resizing = false
			resize_note = null
			queue_redraw()
	
	# IF MOUSE DRAG
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if selecting:
			select_current = mm.position
			queue_redraw()
		elif dragging:
			drag_current_beat = snap_beat(mm.position.y / pixels_per_beat)
			queue_redraw()
		elif resizing:
			var raw_beat: float = mm.position.y / pixels_per_beat
			var snapped: float = snap_beat(raw_beat)
			var min_end: float = resize_note.beat_start + (1.0 / snap_divisor)
			resize_note.beat_end = max(snapped, min_end)
			queue_redraw()


func _finish_drag() -> void:
	var beat_start = min(drag_start_beat, drag_current_beat)
	var beat_end   = max(drag_start_beat, drag_current_beat)
	
	if beat_start < 0:
		return
	
	var note: NoteData
	if beat_end - beat_start < (1.0 / snap_divisor):
		note = chart.add_note(beat_start, drag_lane, current_mode)
	else:
		note = chart.add_note(beat_start, drag_lane, current_mode, beat_end)
	last_placed_note = note
	
	var undo_fn := func():
		chart.remove_note(note)
		if last_placed_note == note:
			last_placed_note = null
	var redo_fn := func():
		chart.notes.append(note)
		chart.sort_notes()
		last_placed_note = note
	_push_undo(undo_fn, redo_fn)
	queue_redraw()


func _finish_select() -> void:
	var x1: float = min(select_start.x, select_current.x)
	var x2: float = max(select_start.x, select_current.x)
	var y1: float = min(select_start.y, select_current.y)
	var y2: float = max(select_start.y, select_current.y)
	
	var lane_min := clampi(int(x1 / lane_width), 0, lane_count - 1)
	var lane_max := clampi(int(x2 / lane_width), 0, lane_count - 1)
	var beat_min := y1 / pixels_per_beat
	var beat_max := y2 / pixels_per_beat
	
	selected_notes.clear()
	for n in chart.notes:
		if n.lane < lane_min or n.lane > lane_max:
			continue
		var n_end: float = n.beat_end if n.is_hold_note() else n.beat_start
		if n.beat_start <= beat_max and n_end >= beat_min:
			selected_notes.append(n)
	
	queue_redraw()
	print("[SELECT] %d notes selected" % selected_notes.size())


func deselect_notes() -> void:
	if selected_notes.is_empty():
		return
	selected_notes.clear()
	queue_redraw()
	print("[SELECT] Cleared")


func copy_selected() -> void:
	if selected_notes.is_empty():
		print("[COPY] Nothing selected")
		return
	
	var earliest_beat := selected_notes[0].beat_start
	for n in selected_notes:
		earliest_beat = min(earliest_beat, n.beat_start)
	
	var anchor_lane := selected_notes[0].lane
	for n in selected_notes:
		if is_equal_approx(n.beat_start, earliest_beat):
			anchor_lane = n.lane
			break
	
	clipboard.clear()
	for n in selected_notes:
		clipboard.append({
			"beat_offset": n.beat_start - earliest_beat,
			"lane_offset": n.lane - anchor_lane,
			"hold_length": (n.beat_end - n.beat_start) if n.is_hold_note() else 0.0,
			"mode": n.mode,
		})
	
	print("[COPY] %d notes copied" % clipboard.size())


func paste_at_anchor() -> void:
	if clipboard.is_empty():
		print("[PASTE] Clipboard empty — copy something first")
		return
	if last_placed_note == null:
		print("[PASTE] No anchor — place a note first, then paste")
		return
		
	var anchor_note := last_placed_note
	var anchor_beat := anchor_note.beat_start
	var anchor_lane := anchor_note.lane
	chart.remove_note(anchor_note)
	last_placed_note = null
	
	var new_notes: Array[NoteData] = []
	var skipped := 0
	for entry in clipboard:
		var new_beat: float = anchor_beat + entry["beat_offset"]
		var new_lane: int = anchor_lane + int(entry["lane_offset"])
		if new_lane < 0 or new_lane >= lane_count:
			skipped += 1
			continue
		var hold_length: float = entry["hold_length"]
		var new_note := chart.add_note(new_beat, new_lane, entry["mode"], new_beat + hold_length if hold_length > 0.0 else 0.0)
		new_notes.append(new_note)
	
	if skipped > 0:
		print("[PASTE] %d note(s) skipped — would land outside valid lanes" % skipped)
	
	var undo_fn := func():
		for n in new_notes:
			chart.remove_note(n)
		chart.notes.append(anchor_note)
		chart.sort_notes()
		last_placed_note = anchor_note
	var redo_fn := func():
		chart.remove_note(anchor_note)
		for n in new_notes:
			chart.notes.append(n)
		chart.sort_notes()
		last_placed_note = null
	_push_undo(undo_fn, redo_fn)
	
	queue_redraw()


func delete_selected() -> void:
	if selected_notes.is_empty():
		print("[DELETE] Nothing selected")
		return
	
	var removed_notes: Array[NoteData] = selected_notes.duplicate()
	for n in removed_notes:
		chart.remove_note(n)
		if last_placed_note == n:
			last_placed_note = null
	selected_notes.clear()
	
	var undo_fn := func():
		for n in removed_notes:
			chart.notes.append(n)
		chart.sort_notes()
	var redo_fn := func():
		for n in removed_notes:
			chart.remove_note(n)
	_push_undo(undo_fn, redo_fn)
	
	queue_redraw()
	print("[DELETE] %d notes removed" % removed_notes.size())


func _push_undo(undo_fn: Callable, redo_fn: Callable) -> void:
	undo_stack.append({"undo": undo_fn, "redo": redo_fn})
	if undo_stack.size() > MAX_UNDO_HISTORY:
		undo_stack.pop_front()
	redo_stack.clear()


func undo() -> void:
	if undo_stack.is_empty():
		print("[UNDO] Nothing to undo")
		return
	var cmd: Dictionary = undo_stack.pop_back()
	cmd["undo"].call()
	redo_stack.append(cmd)
	queue_redraw()
	print("[UNDO] %d left" % undo_stack.size())


func redo() -> void:
	if redo_stack.is_empty():
		print("[REDO] Nothing to redo")
		return
	var cmd: Dictionary = redo_stack.pop_back()
	cmd["redo"].call()
	undo_stack.append(cmd)
	queue_redraw()
	print("[REDO] %d left" % redo_stack.size())


func flash_offset_feedback() -> void:
	offset_feedback_timer = 1.0
	queue_redraw()


func snap_beat(raw_beat: float) -> float:
	var step := 1.0 / snap_divisor
	return round(raw_beat / step) * step


func _find_note_near(raw_beat: float, lane: int, mode: String) -> NoteData:
	var tolerance := NOTE_HIT_TOLERANCE_PX / pixels_per_beat
	for n in chart.notes:
		if n.lane != lane or n.mode != mode:
			continue
		if n.is_hold_note():
			if raw_beat >= n.beat_start - tolerance and raw_beat <= n.beat_end + tolerance:
				return n
		else:
			if abs(n.beat_start - raw_beat) <= tolerance:
				return n
	return null


func _find_resize_handle(raw_beat: float, lane: int) -> NoteData:
	var tolerance := RESIZE_HANDLE_TOLERANCE_PX / pixels_per_beat
	for n in chart.notes:
		if n.lane != lane or n.mode != current_mode:
			continue
		if n.is_hold_note() and abs(n.beat_end - raw_beat) <= tolerance:
			return n
	return null


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


# UI
func _draw() -> void:
	_draw_lanes()
	_draw_grid_lines()
	_draw_notes()
	_draw_selection()
	_draw_clipboard_preview()
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


func _draw_playhead() -> void:
	var y := playhead_beat * pixels_per_beat
	draw_line(Vector2(0, y), Vector2(lane_count * lane_width, y), Color.RED, 2.0)
	
	if chart:
		var flashing: bool = offset_feedback_timer > 0.0
		var label_color: Color = Color.YELLOW if flashing else Color(1, 1, 1, 0.6)
		var label_size: int = 16 if flashing else 12
		draw_string(ThemeDB.fallback_font, Vector2(8, y - 10), "Offset: %.3fs" % chart.offset, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, label_color)


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
			draw_rect(Rect2(x + 4, y_top - 4, lane_width - 8, 8), color)
			if n.mode == current_mode:
				draw_rect(Rect2(x + lane_width / 2.0 - 4, y_bottom - 4, 8, 8), Color.WHITE)
		else:
			var y := n.beat_start * pixels_per_beat
			draw_rect(Rect2(x + 4, y - 4, lane_width - 8, 8), color)
	
	# live drag preview
	if dragging:
		var x := drag_lane * lane_width
		var y_top = min(drag_start_beat, drag_current_beat) * pixels_per_beat
		var y_bottom = max(drag_start_beat, drag_current_beat) * pixels_per_beat
		draw_rect(Rect2(x + 4, y_top, lane_width - 8, max(y_bottom - y_top, 1)), Color(1, 1, 1, 0.3))
	
	if resizing and resize_note:
		var x := resize_note.lane * lane_width
		var y := resize_note.beat_end * pixels_per_beat
		draw_rect(Rect2(x + lane_width / 2.0 - 5, y - 5, 10, 10), Color.RED)


func _draw_selection() -> void:
	if selecting:
		var x1: float = min(select_start.x, select_current.x)
		var x2: float = max(select_start.x, select_current.x)
		var y1: float = min(select_start.y, select_current.y)
		var y2: float = max(select_start.y, select_current.y)
		draw_rect(Rect2(x1, y1, x2 - x1, y2 - y1), Color(1, 1, 0, 0.15))
		draw_rect(Rect2(x1, y1, x2 - x1, y2 - y1), Color(1, 1, 0, 0.6), false, 1.5)

	for n in selected_notes:
		var x := n.lane * lane_width
		var y_top := n.beat_start * pixels_per_beat
		var y_bottom := (n.beat_end if n.is_hold_note() else n.beat_start) * pixels_per_beat
		draw_rect(Rect2(x + 2, y_top - 6, lane_width - 4, max(y_bottom - y_top, 1) + 12), Color.YELLOW, false, 2.0)


func _draw_clipboard_preview() -> void:
	if clipboard.is_empty():
		return
	
	draw_string(ThemeDB.fallback_font, Vector2(8, 16), "Clipboard: %d note(s)" % clipboard.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.5))
	
	if last_placed_note == null:
		return
	
	var anchor_beat: float = last_placed_note.beat_start
	var anchor_lane: int = last_placed_note.lane
	for entry in clipboard:
		var beat: float = anchor_beat + entry["beat_offset"]
		var lane: int = anchor_lane + int(entry["lane_offset"])
		if lane < 0 or lane >= lane_count:
			continue
		var x := lane * lane_width
		var hold_length: float = entry["hold_length"]
		if hold_length > 0.0:
			var y_top := beat * pixels_per_beat
			var y_bottom := (beat + hold_length) * pixels_per_beat
			draw_rect(Rect2(x + 4, y_top, lane_width - 8, y_bottom - y_top), Color(1, 1, 1, 0.25))
		else:
			var y := beat * pixels_per_beat
			draw_rect(Rect2(x + 4, y - 4, lane_width - 8, 8), Color(1, 1, 1, 0.4))
