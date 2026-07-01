extends Resource
class_name ChartData

@export var song_name: String                    # song title
@export var artist: String                       # artist name
@export var bpm: float                           # the 'real' bpm of the song (search it)
@export var offset: float = 0.0                  # song start offset
@export var stream: AudioStream                  # the music file
@export var notes: Array[NoteData] = []          # list of NoteData resources
@export var scale_events: Array[ScaleEvent] = [] # list of ScaleData manips


func add_note(beat_start: float, lane: int, mode: String, is_lite: bool, beat_end: float = 0.0) -> NoteData:
	var note := NoteData.new()
	note.beat_start = beat_start
	note.beat_end = beat_end
	note.lane = lane
	note.mode = mode
	note.is_lite = is_lite
	notes.append(note)
	sort_notes()
	return note


func remove_note(note: NoteData) -> void:
	notes.erase(note)


func sort_notes() -> void:
	notes.sort_custom(func(a, b): return a.beat_start < b.beat_start)


func get_note_at(beat: float, lane: int, mode: String) -> NoteData:
	for n in notes:
		if n.lane == lane and n.mode == mode and is_equal_approx(n.beat_start, beat):
			return n
	return null


func total_notes() -> int:
	# tap notes count as 1
	# hold notes count as beat_duration slices
	var count: int = 0
	for note in notes:
		if note.is_hold_note():
			count += int(round(note.beat_end - note.beat_start))
		else:
			count += 1
	return count


func add_scale_event(beat: float, target_scale: float, duration_beats: float = 0.5) -> ScaleEvent:
	var ev := ScaleEvent.new()
	ev.beat = beat
	ev.target_scale = target_scale
	ev.duration_beats = duration_beats
	scale_events.append(ev)
	scale_events.sort_custom(func(a, b): return a.beat < b.beat)
	return ev


func remove_scale_event(ev: ScaleEvent) -> void:
	scale_events.erase(ev)


func get_scale_event_at(beat: float, tolerance: float = 0.05) -> ScaleEvent:
	for ev in scale_events:
		if abs(ev.beat - beat) <= tolerance:
			return ev
	return null
