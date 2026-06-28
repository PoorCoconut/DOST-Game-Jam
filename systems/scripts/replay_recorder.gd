extends Node

var _current_replay: ReplayData = null
var _chart: ChartData = null


func start_recording(chart: ChartData) -> void:
	print("[REPLAY] start_recording called for: ", chart.song_name)
	_chart = chart
	_current_replay = ReplayData.new()
	_current_replay.chart = chart
	_current_replay.entries = []

	# Listen for standard song completion
	if not Conductor.song_finished.is_connected(_on_song_finished):
		Conductor.song_finished.connect(_on_song_finished)
		print("[REPLAY] connected to Conductor.song_finished")
	else:
		print("[REPLAY] already connected to Conductor.song_finished")

	# NEW: Listen for player failure so data saves immediately before scene changes
	if not ScoreSystem.player_failed.is_connected(_on_song_finished):
		ScoreSystem.player_failed.connect(_on_song_finished)
		print("[REPLAY] connected to ScoreSystem.player_failed")


func record_tap(beat_start: float, lane: int, mode: String, judgment: String, time_diff: float) -> void:
	if _current_replay == null:
		return
		
	var entry := {
		"beat_start": beat_start,
		"lane": lane,
		"mode": mode,
		"judgment": judgment,
		"time_offset": time_diff, 
		"is_hold": false,
		"time_of_release": -1.0
	}
	_current_replay.entries.append(entry)


func record_hold(beat_start: float, lane: int, mode: String, judgment: String, time_of_press_offset: float, time_of_release_offset: float, beat_end: float) -> void:
	print("[REC_DEBUG] Recording Hold -> StartBeat: %f | EndBeat: %f | PressOffset: %f | ReleaseOffset: %f" % [beat_start, beat_end, time_of_press_offset, time_of_release_offset])
	if _current_replay == null:
		return
		
	var entry := {
		"beat_start": beat_start,
		"beat_end": beat_end,
		"lane": lane,
		"mode": mode,
		"judgment": judgment,
		"time_offset": time_of_press_offset,
		"is_hold": true,
		"time_of_release_offset": time_of_release_offset
	}
	_current_replay.entries.append(entry)


func _on_song_finished() -> void:
	print("[REPLAY] _on_song_finished called")
	if _current_replay == null or _chart == null:
		print("[REPLAY] replay or chart is null, aborting save")
		return
		
	# snapshot final score state
	_current_replay.final_watts = roundi(ScoreSystem.watts)
	_current_replay.final_volts = ScoreSystem.volts
	_current_replay.final_rank = ScoreSystem.get_rank()
	_current_replay.perfects = ScoreSystem.perfects
	_current_replay.goods = ScoreSystem.goods
	_current_replay.bads = ScoreSystem.bads
	_current_replay.misses = ScoreSystem.misses
	_save_replay()


func _save_replay() -> void:
	var dir = "user://replays/"
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)

	# named as songname_replay.tres, overwrites previous run
	var file_name = _chart.song_name.to_lower().replace(" ", "_") + "_replay.tres"
	var path = dir + file_name

	var err = ResourceSaver.save(_current_replay, path)
	if err == OK:
		print("[REPLAY] Saved replay to: ", path)
	else:
		push_error("[REPLAY] Failed to save replay: " + str(err))
