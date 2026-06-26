extends Resource
class_name ChartData

@export var song_name: String            # song title
@export var artist: String               # artist name
@export var bpm: float                   # the 'real' bpm of the song (search it)
@export var stream: AudioStream          # the music file
@export var notes: Array[NoteData] = []  # list of NoteData resources


func add_note(beat_start: float, lane: int, mode: String, beat_end: float = 0.0) -> NoteData:
	var note := NoteData.new()
	note.beat_start = beat_start
	note.beat_end = beat_end
	note.lane = lane
	note.mode = mode
	notes.append(note)
	sort_notes()
	return note


func remove_note(note: NoteData) -> void:
	notes.erase(note)


func sort_notes() -> void:
	notes.sort_custom(func(a, b): return a.beat_start < b.beat_start)


func get_note_at(beat: float, lane: int, mode: String, tolerance: float = 0.05) -> NoteData:
	for n in notes:
		if n.lane == lane and n.mode == mode and abs(n.beat_start - beat) <= tolerance:
			return n
	return null


func total_notes() -> int:
	# tap notes count as 1, hold notes count as beat_duration slices
	var count: int = 0
	for note in notes:
		if note.is_hold_note():
			count += int(round(note.beat_end - note.beat_start))
		else:
			count += 1
	return count
